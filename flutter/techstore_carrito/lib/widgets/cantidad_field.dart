import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Quantity shown as plain text; tapping it turns it into a numeric text field.
/// Digits only (letters, emojis and symbols are rejected). Values above [stock]
/// are clamped and reported through [onExceso]; empty/0 reverts to the last
/// valid quantity when the field loses focus.
class CantidadField extends StatefulWidget {
  final int cantidad;
  final int stock;
  final ValueChanged<int> onChanged;
  final VoidCallback onExceso;

  const CantidadField({
    super.key,
    required this.cantidad,
    required this.stock,
    required this.onChanged,
    required this.onExceso,
  });

  @override
  State<CantidadField> createState() => _CantidadFieldState();
}

class _CantidadFieldState extends State<CantidadField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  bool _editando = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: "${widget.cantidad}");
    _focus = FocusNode()..addListener(_alCambiarFoco);
  }

  @override
  void didUpdateWidget(CantidadField old) {
    super.didUpdateWidget(old);
    // keep in sync with the +/- buttons
    if (int.tryParse(_controller.text) != widget.cantidad && !_focus.hasFocus) {
      _controller.text = "${widget.cantidad}";
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _editar() {
    setState(() => _editando = true);
    _controller.value = TextEditingValue(
      text: "${widget.cantidad}",
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: "${widget.cantidad}".length,
      ),
    );
  }

  void _alCambiarFoco() {
    if (_focus.hasFocus) return;
    final valor = int.tryParse(_controller.text);
    if (valor == null || valor < 1) {
      _controller.text = "${widget.cantidad}";
    }
    if (mounted) setState(() => _editando = false);
  }

  void _alEscribir(String texto) {
    final valor = int.tryParse(texto);
    if (valor == null || valor < 1) return; // wait until a valid number
    if (valor > widget.stock) {
      _controller.value = TextEditingValue(
        text: "${widget.stock}",
        selection: TextSelection.collapsed(offset: "${widget.stock}".length),
      );
      widget.onExceso();
      widget.onChanged(widget.stock);
      return;
    }
    widget.onChanged(valor);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 40,
      child: _editando ? _campo() : _texto(),
    );
  }

  Widget _texto() {
    return Tooltip(
      message: "Toca para escribir la cantidad",
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _editar,
        child: Center(
          child: Text(
            "${widget.cantidad}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo() {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      autofocus: true,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      // only 0-9: blocks letters, e, +, -, ., symbols and emojis (also on paste)
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      decoration: const InputDecoration(
        isDense: true,
        counterText: "",
        contentPadding: EdgeInsets.symmetric(vertical: 8),
        border: OutlineInputBorder(),
      ),
      onChanged: _alEscribir,
      onSubmitted: (_) => _focus.unfocus(),
    );
  }
}
