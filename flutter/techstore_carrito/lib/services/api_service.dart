import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:techstore_carrito/models/factura.dart';
import 'package:techstore_carrito/models/item_carrito.dart';
import 'package:techstore_carrito/models/producto.dart';

class ApiException implements Exception {
  final String mensaje;
  final String? codigo;
  ApiException(this.mensaje, {this.codigo});

  bool get sinStock => codigo == "STOCK_INSUFICIENTE";

  @override
  String toString() => mensaje;
}

class ApiService {
  // 10.0.2.2 is the Android emulator's alias for the host machine
  static final String baseUrl =
      defaultTargetPlatform == TargetPlatform.android && !kIsWeb
          ? 'http://10.0.2.2:5000'
          : 'http://localhost:5000';

  Future<List<Producto>> obtenerProducto() async {
    final url = Uri.parse("$baseUrl/api/productos");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Producto.fromJson(json)).toList();
    } else {
      throw Exception(
        "Error ${response.statusCode}: "
        "No se pudieron obtener los productos del servidor",
      );
    }
  }

  Future<Factura> generarFactura(List<ItemCarrito> carrito) async {
    final url = Uri.parse("$baseUrl/api/facturas");
    final datosCompra = {
      "factura": {
        "numero": "F001-${DateTime.now().millisecondsSinceEpoch}",
        "fecha": DateTime.now().toIso8601String().substring(0, 10),
      },
      "cliente": {"nombre": "Juan Perez", "cedula_ruc": "1234567890"},
      "detalles": carrito.map((item) => item.toJsonFactura()).toList(),
    };
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(datosCompra),
    );
    if (response.statusCode == 200) {
      return Factura.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw ApiException(
        body is Map && body["mensaje"] != null
            ? body["mensaje"]
            : "Error ${response.statusCode}",
        codigo: body is Map ? body["codigo"] : null,
      );
    }
  }
}
