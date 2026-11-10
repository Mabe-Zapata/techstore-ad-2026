from flask import Blueprint, request, jsonify

from data.factura_data import (
    registrar_factura, StockInsuficiente, ProductoNoExiste, FacturaDuplicada,
)
from models.factura_model import validar_datos, generar_factura_xml

factura_bp = Blueprint("factura", __name__)


@factura_bp.route("/api/facturas", methods=["POST"])
def generar_factura():

    datos = request.get_json(silent=True)

    errores = validar_datos(datos)

    if errores:
        return jsonify({
            "errores": errores,
            "estado": "Error",
            "mensaje": "Datos de la factura inválidos"
        }), 400

    try:
        totales = registrar_factura(datos, generar_factura_xml)
    except StockInsuficiente as e:
        return jsonify({
            "estado": "Error", "codigo": "STOCK_INSUFICIENTE", "mensaje": str(e)
        }), 409
    except (FacturaDuplicada, ProductoNoExiste) as e:
        return jsonify({"estado": "Error", "codigo": "CONFLICTO", "mensaje": str(e)}), 409

    return jsonify({
        "estado": "Generada",
        "mensaje": "Factura generada correctamente",
        "factura": datos,
        "totales": {k: totales[k] for k in ("subtotal", "iva", "total")},
        "xml": totales["xml"]
    }), 200
