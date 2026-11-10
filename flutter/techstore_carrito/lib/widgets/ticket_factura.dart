import 'package:flutter/material.dart';
import '../models/factura.dart';

/// Thermal-receipt style view of an invoice.
class TicketFactura extends StatelessWidget {
  final Factura factura;
  const TicketFactura({super.key, required this.factura});

  static const _mono = TextStyle(
    fontFamily: "monospace",
    fontSize: 13,
    color: Colors.black87,
    height: 1.4,
  );

  Widget _separador() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Text(
          "- - - - - - - - - - - - - - - - - - - - - - - -",
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: _mono,
        ),
      );

  Widget _fila(String izq, String der, {bool negrita = false}) {
    final estilo = negrita
        ? _mono.copyWith(fontWeight: FontWeight.bold, fontSize: 15)
        : _mono;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(izq, style: estilo)),
        Text(der, style: estilo),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEF9),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "TECHSTORE 360",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "monospace",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text("FACTURA", textAlign: TextAlign.center, style: _mono),
              _separador(),
              _fila("N°:", factura.numero),
              _fila("Fecha:", factura.fecha),
              _fila("Cliente:", factura.cliente),
              _fila("CI/RUC:", factura.cedulaRuc),
              _separador(),
              _fila("CANT  DESCRIPCION", "TOTAL", negrita: false),
              const SizedBox(height: 4),
              for (final l in factura.lineas) ...[
                _fila("${l.cantidad} x ${l.nombre}",
                    "\$${l.subtotal.toStringAsFixed(2)}"),
                Text("     @ \$${l.precioUnitario.toStringAsFixed(2)}",
                    style: _mono.copyWith(color: Colors.black54)),
              ],
              _separador(),
              _fila("Subtotal", "\$${factura.subtotal.toStringAsFixed(2)}"),
              _fila("IVA 15%", "\$${factura.iva.toStringAsFixed(2)}"),
              const SizedBox(height: 4),
              _fila("TOTAL", "\$${factura.total.toStringAsFixed(2)}", negrita: true),
              _separador(),
              const Text("¡Gracias por su compra!",
                  textAlign: TextAlign.center, style: _mono),
            ],
          ),
        ),
      ),
    );
  }
}
