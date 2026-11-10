class LineaFactura {
  final String nombre;
  final int cantidad;
  final double precioUnitario;

  LineaFactura({
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;
}

class Factura {
  final String numero;
  final String fecha;
  final String cliente;
  final String cedulaRuc;
  final List<LineaFactura> lineas;
  final double subtotal;
  final double iva;
  final double total;
  final String xml;

  Factura({
    required this.numero,
    required this.fecha,
    required this.cliente,
    required this.cedulaRuc,
    required this.lineas,
    required this.subtotal,
    required this.iva,
    required this.total,
    required this.xml,
  });

  factory Factura.fromJson(Map<String, dynamic> json) {
    final f = json["factura"] as Map<String, dynamic>;
    final t = json["totales"] as Map<String, dynamic>;
    return Factura(
      numero: f["factura"]["numero"].toString(),
      fecha: f["factura"]["fecha"].toString(),
      cliente: f["cliente"]["nombre"].toString(),
      cedulaRuc: f["cliente"]["cedula_ruc"].toString(),
      lineas: (f["detalles"] as List)
          .map((d) => LineaFactura(
                nombre: d["nombre"],
                cantidad: d["cantidad"],
                precioUnitario: (d["precio_unitario"] as num).toDouble(),
              ))
          .toList(),
      subtotal: (t["subtotal"] as num).toDouble(),
      iva: (t["iva"] as num).toDouble(),
      total: (t["total"] as num).toDouble(),
      xml: json["xml"] ?? "",
    );
  }
}
