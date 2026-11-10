from data.db import get_connection

IVA = 0.15


class StockInsuficiente(Exception):
    pass


class ProductoNoExiste(Exception):
    pass


class FacturaDuplicada(Exception):
    pass


def registrar_factura(datos, generar_xml):
    """Saves the invoice and discounts stock in ONE transaction.

    The discount is an atomic `UPDATE ... WHERE stock >= cantidad`: SQL Server
    locks the row, so with 80 in stock and two buyers asking 50 each, the first
    wins and the second matches 0 rows -> StockInsuficiente -> full rollback.
    Rewrites datos["detalles"] with name/price taken from the DB, builds the XML
    with generar_xml(datos) (inside the transaction) and stores it with the invoice.
    Returns {"subtotal", "iva", "total", "xml"}.
    """
    # merge repeated products; sorted ids = same lock order everywhere (no deadlocks)
    pedido = {}
    for d in datos["detalles"]:
        pid = int(d["producto_id"])
        pedido[pid] = pedido.get(pid, 0) + int(d["cantidad"])

    conn = get_connection()
    try:
        cur = conn.cursor()
        detalles = []
        subtotal = 0.0

        for pid in sorted(pedido):
            cantidad = pedido[pid]
            # rowcount must be read right after the UPDATE, before any other statement
            descontadas = cur.execute(
                "UPDATE dbo.PRODUCTOS SET STOCK = STOCK - ? WHERE ID = ? AND STOCK >= ?",
                cantidad, pid, cantidad,
            ).rowcount
            fila = cur.execute(
                "SELECT NOMBRE AS nombre, PRECIO AS precio, STOCK AS stock FROM dbo.PRODUCTOS WHERE ID = ?", pid
            ).fetchone()
            if fila is None:
                raise ProductoNoExiste(f"El producto {pid} no existe")
            if descontadas == 0:
                # stock is read after the failed UPDATE only for the message
                raise StockInsuficiente(
                    f"Stock insuficiente para {fila.nombre}: "
                    f"disponible {fila.stock}, solicitado {cantidad}"
                )
            precio = float(fila.precio)
            subtotal += precio * cantidad
            detalles.append((pid, fila.nombre, cantidad, precio))

        iva = subtotal * IVA
        f, c = datos["factura"], datos["cliente"]
        if cur.execute("SELECT 1 FROM dbo.FACTURAS WHERE NUMERO = ?", f["numero"]).fetchone():
            raise FacturaDuplicada(f"La factura {f['numero']} ya existe")

        datos["detalles"] = [
            {"nombre": n, "cantidad": q, "precio_unitario": p} for _, n, q, p in detalles
        ]
        xml = generar_xml(datos)

        factura_id = cur.execute(
            "INSERT INTO dbo.FACTURAS (NUMERO, FECHA, CLIENTE, CEDULA_RUC, SUBTOTAL, IVA, TOTAL, XML) "
            "OUTPUT INSERTED.ID VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            f["numero"], f["fecha"], c["nombre"], c["cedula_ruc"],
            round(subtotal, 2), round(iva, 2), round(subtotal + iva, 2), xml,
        ).fetchone()[0]

        for pid, _, cantidad, precio in detalles:
            cur.execute(
                "INSERT INTO dbo.FACTURA_DETALLE (FACTURA_ID, PRODUCTO_ID, CANTIDAD, PRECIO_UNITARIO) "
                "VALUES (?, ?, ?, ?)",
                factura_id, pid, cantidad, precio,
            )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    return {
        "subtotal": round(subtotal, 2),
        "iva": round(iva, 2),
        "total": round(subtotal + iva, 2),
        "xml": xml,
    }
