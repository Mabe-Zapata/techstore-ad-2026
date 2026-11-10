import xml.etree.ElementTree as ET
from datetime import date

iva_general = 0.15


def validar_datos(datos):
    errores = []
    
    factura = datos.get("factura")
    if not isinstance(factura, dict):
        errores.append({
            "campo": "factura",
            "error": "La factura es requerida"
        })
    else:
        if not factura.get("numero"):
            errores.append(
                {
                    "campo":"numero",
                    "error": "El numero de factura es requerido"
                }
            )

        if not factura.get("fecha"):
            errores.append(
                {
                    "campo":"fecha",
                    "error": "La fecha de la factura es requerida"
                }
            )

    if datos is None or len(datos) == 0:
        errores.append({
            "campo": "body",
            "error": "Json esta vacio o no es valido"
        })
        return errores

    # Validar factura
    factura = datos.get("factura")

    if not isinstance(factura, dict):
        errores.append({
            "campo": "factura",
            "error": "La factura es obligatoria y debe ser un objeto"
        })
    else:
        if not factura.get("numero"):
            errores.append({
                "campo": "factura.numero",
                "error": "El numero de la factura es obligatorio"
            })

        if not factura.get("fecha"):
            errores.append({
                "campo": "factura.fecha",
                "error": "La fecha de la factura es obligatoria"
            })
        else:
            try:
                date.fromisoformat(str(factura["fecha"]))
            except ValueError:
                errores.append({
                    "campo": "factura.fecha",
                    "error": "La fecha debe tener formato YYYY-MM-DD"
                })

    # Validar cliente
    clientes = datos.get("cliente")

    if not isinstance(clientes, dict):
        errores.append({
            "campo": "cliente",
            "error": "El cliente requerido y debe ser un objeto"
        })
    else:
        if not clientes.get("nombre"):
            errores.append({
                "campo": "cliente.nombre",
                "error": "El nombre del cliente es obligatorio"
            })

        if not clientes.get("cedula_ruc"):
            errores.append({
                "campo": "cliente.cedula_ruc",
                "error": "La cedula o RUC del cliente es obligatorio"
            })

    # Validar productos
    productos = datos.get("detalles")

    if not isinstance(productos, list) or len(productos) == 0:
        errores.append({
            "campo": "productos",
            "error": "La lista de productos es obligatoria y debe contener al menos un producto"
        })
    else:
        for i, producto in enumerate(productos, start=1):

            if not isinstance(producto, dict):
                errores.append({
                    "campo": f"productos[{i}]",
                    "error": "Cada producto debe ser un objeto"
                })
                continue

            try:
                producto_id = int(producto.get("producto_id"))
                if producto_id <= 0:
                    raise ValueError
            except (ValueError, TypeError):
                errores.append({
                    "campo": f"productos[{i}].producto_id",
                    "error": "El producto_id es obligatorio y debe ser un entero positivo"
                })

            cantidad = producto.get("cantidad")
            if isinstance(cantidad, bool) or not isinstance(cantidad, int) or cantidad <= 0:
                errores.append({
                    "campo": f"productos[{i}].cantidad",
                    "error": "La cantidad debe ser un entero mayor que cero"
                })

    return errores


def generar_factura_xml(datos):

    subtotal_real = 0.0

    factura = ET.Element("Factura")
    cabecera = ET.SubElement(factura, "Cabecera")

    ET.SubElement(cabecera, "Numero").text = str(datos["factura"]["numero"])

    ET.SubElement(cabecera, "Fecha").text = str(datos["factura"]["fecha"])

    cliente = ET.SubElement(factura, "Cliente")

    ET.SubElement(cliente, "Nombre").text = str(datos["cliente"]["nombre"])

    ET.SubElement(cliente, "CedulaRUC").text = str(datos["cliente"]["cedula_ruc"])

    detalle = ET.SubElement(factura, "Detalle")

    productos = datos["detalles"]

    for producto in productos:

        nombre = producto["nombre"]
        cantidad = float(producto["cantidad"])
        precio = float(producto["precio_unitario"])

        subtotal_producto = cantidad * precio
        subtotal_real += subtotal_producto

        producto_xml = ET.SubElement(detalle, "Producto")

        ET.SubElement(producto_xml, "Nombre").text = str(nombre)
        ET.SubElement(producto_xml, "Cantidad").text = str(cantidad)
        ET.SubElement(producto_xml, "Preciounitario").text = f"{precio:.2f}"
        ET.SubElement(producto_xml, "Subtotal").text = f"{subtotal_producto:.2f}"

    iva_total = subtotal_real * iva_general
    total = subtotal_real + iva_total

    totales = ET.SubElement(factura, "Totales")

    ET.SubElement(totales, "Subtotal").text = f"{subtotal_real:.2f}"
    ET.SubElement(totales, "IVA").text = f"{iva_total:.2f}"
    ET.SubElement(totales, "Total").text = f"{total:.2f}"

    ET.SubElement(factura, "Estado").text = "Generada"
    
    ET.indent(factura, space=" ", level=0)

    return ET.tostring(factura, encoding="unicode", xml_declaration=True)
