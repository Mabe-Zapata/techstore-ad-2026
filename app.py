# API
from flask import Flask
from flask_cors import CORS

from controllers.producto_controller import producto_bp
from controllers.factura_controller import factura_bp

app = Flask(__name__)
CORS(app)

app.register_blueprint(producto_bp)
app.register_blueprint(factura_bp)


@app.route("/")
def inicio():
    return "Bienvenido a TechStore Facturacion"


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True)
