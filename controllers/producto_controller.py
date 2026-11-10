from flask import Blueprint, jsonify

from data.productos_data import listar_productos

producto_bp = Blueprint("producto", __name__)


@producto_bp.route("/api/productos", methods=["GET"])
def obtener_productos():
    return jsonify(listar_productos()), 200
