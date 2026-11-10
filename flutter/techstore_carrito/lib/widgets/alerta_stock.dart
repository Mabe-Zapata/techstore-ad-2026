import 'package:flutter/material.dart';

/// SweetAlert-style modal: animated icon, title, message and one button.
Future<void> mostrarAlertaStock(BuildContext context, String mensaje) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              builder: (context, escala, hijo) =>
                  Transform.scale(scale: escala, child: hijo),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300, width: 3),
                ),
                child: Icon(
                  Icons.production_quantity_limits,
                  size: 44,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Stock no disponible",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              "Otro cliente compró antes que tú. Revisa tu carrito, "
              "ya se actualizó con el stock actual.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Entendido"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
