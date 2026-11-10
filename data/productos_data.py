from data.db import get_connection


def listar_productos():
    with get_connection() as conn:
        filas = conn.cursor().execute(
            "SELECT ID AS id, NOMBRE AS nombre, PRECIO AS precio, STOCK AS stock, "
            "IMAGENURL AS imagen FROM dbo.PRODUCTOS ORDER BY ID"
        ).fetchall()
    return [
        {
            "id": f.id,
            "nombre": f.nombre,
            "precio": float(f.precio),
            "stock": f.stock,
            "imagenUrl": f.imagen or "",
        }
        for f in filas
    ]
