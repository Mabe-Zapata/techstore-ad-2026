import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../models/item_carrito.dart';
import '../models/factura.dart';
import '../services/api_service.dart';
import '../widgets/alerta_stock.dart';
import '../widgets/cantidad_field.dart';
import '../widgets/ticket_factura.dart';

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  final ApiService apiService = ApiService();
  List<Producto> productos = [];
  List<ItemCarrito> carrito = [];
  bool cargandoProductos = true;
  bool generandoFactura = false;
  Factura? factura;
  bool verXml = false;
  String filtro = "";
  String mensajeError = "";

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  Future<void> cargarProductos() async {
    setState(() {
      cargandoProductos = true;
      mensajeError = "";
    });
    try {
      final data = await apiService.obtenerProducto();
      if (!mounted) return;
      setState(() {
        productos = data;
        // re-sync cart with fresh stock: drop sold-out items, clamp quantities
        carrito = [
          for (final item in carrito)
            for (final p in data.where((p) => p.id == item.producto.id))
              if (p.stock > 0)
                ItemCarrito(
                  producto: p,
                  cantidad: item.cantidad > p.stock ? p.stock : item.cantidad,
                ),
        ];
        cargandoProductos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        mensajeError = e.toString();
        cargandoProductos = false;
      });
    }
  }

  void agregarAlCarrito(Producto producto) {
    final index = carrito.indexWhere((item) => item.producto.id == producto.id);
    final cantidadActual = index >= 0 ? carrito[index].cantidad : 0;
    if (cantidadActual >= producto.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No hay suficiente stock para ${producto.nombre}"),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      if (index >= 0) {
        carrito[index].cantidad++;
      } else {
        carrito.add(ItemCarrito(producto: producto));
      }
      factura = null;
      mensajeError = "";
    });
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje), duration: const Duration(seconds: 2)),
      );
  }

  void quitarDelCarrito(ItemCarrito item) {
    final index = carrito.indexWhere(
      (elemento) => elemento.producto.id == item.producto.id,
    );
    if (index == -1) return;
    setState(() {
      if (carrito[index].cantidad > 1) {
        carrito[index].cantidad--;
      } else {
        carrito.removeAt(index);
      }
      factura = null;
      mensajeError = "";
    });
  }

  void limpiarCarrito() {
    setState(() {
      carrito.clear();
      factura = null;
      mensajeError = "";
    });
  }

  double get subtotal {
    return carrito.fold<double>(0.0, (total, item) => total + item.subtotal);
  }

  double get iva {
    return subtotal * 0.15;
  }

  double get total {
    return subtotal + iva;
  }

  Future<void> generarFactura() async {
    if (carrito.isEmpty) {
      setState(() {
        mensajeError = "Debe agregar al menos un producto al carrito.";
        factura = null;
      });
      return;
    }
    setState(() {
      generandoFactura = true;
      factura = null;
      mensajeError = "";
    });
    try {
      final respuesta = await apiService.generarFactura(carrito);
      if (!mounted) return;
      setState(() {
        factura = respuesta;
        verXml = false;
        carrito.clear();
      });
      await cargarProductos();
    } catch (e) {
      await cargarProductos(); // stock may have changed (409)
      if (!mounted) return;
      if (e is ApiException && e.sinStock) {
        await mostrarAlertaStock(context, e.mensaje);
      } else {
        setState(() {
          mensajeError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          generandoFactura = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text(
          "TechStore 360",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Badge(
              isLabelVisible: carrito.isNotEmpty,
              label: Text(
                "${carrito.fold<int>(0, (t, i) => t + i.cantidad)}",
              ),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 850) {
            return _vistaMovil();
          }
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: _panelProductos()),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: _panelCarrito()),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: _panelFactura()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _vistaMovil() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(height: 420, child: _panelProductos()),
          const SizedBox(height: 12),
          SizedBox(height: 420, child: _panelCarrito()),
          const SizedBox(height: 12),
          SizedBox(height: 520, child: _panelFactura()),
        ],
      ),
    );
  }

  Widget _panel({
    required IconData icono,
    required String titulo,
    required Widget hijo,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Expanded(child: hijo),
        ],
      ),
    );
  }

  Widget _chipStock(int stock) {
    final color = stock == 0
        ? Colors.red
        : stock <= 5
            ? Colors.orange
            : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        stock == 0 ? "Agotado" : "Stock: $stock",
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _imagenProducto(Producto producto) {
    final placeholder = Container(
      color: const Color(0xFFEEF0F7),
      child: const Center(
        child: Icon(Icons.devices_other, size: 40, color: Colors.black26),
      ),
    );
    if (producto.imagenUrl.isEmpty) return placeholder;
    return Image.network(
      producto.imagenUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progreso) =>
          progreso == null ? child : placeholder,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }

  Widget _tarjetaProducto(Producto producto) {
    final agotado = producto.stock == 0;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Opacity(
              opacity: agotado ? 0.45 : 1,
              child: _imagenProducto(producto),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "\$${producto.precio.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _chipStock(producto.stock),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: FilledButton.icon(
                    onPressed:
                        agotado ? null : () => agregarAlCarrito(producto),
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text("Agregar"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buscador() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        onChanged: (v) => setState(() => filtro = v.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: "Buscar producto...",
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF3F4F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _panelProductos() {
    final Widget hijo;
    if (cargandoProductos) {
      hijo = const Center(child: CircularProgressIndicator());
    } else if (mensajeError.isNotEmpty && productos.isEmpty) {
      hijo = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(mensajeError, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: cargarProductos,
              child: const Text("Reintentar"),
            ),
          ],
        ),
      );
    } else {
      final visibles = productos
          .where((p) => p.nombre.toLowerCase().contains(filtro))
          .toList();
      hijo = Column(
        children: [
          _buscador(),
          Expanded(
            child: visibles.isEmpty
                ? const Center(
                    child: Text("Sin resultados",
                        style: TextStyle(color: Colors.grey)),
                  )
                : GridView.builder(
                    itemCount: visibles.length,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 210,
                      mainAxisExtent: 250,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, i) => _tarjetaProducto(visibles[i]),
                  ),
          ),
        ],
      );
    }
    return _panel(icono: Icons.storefront, titulo: "Productos", hijo: hijo);
  }

  Widget _lineaCarrito(ItemCarrito item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.producto.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  "\$${item.producto.precio.toStringAsFixed(2)} c/u"
                  " · máx. ${item.producto.stock}",
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => quitarDelCarrito(item),
          ),
          CantidadField(
            key: ValueKey(item.producto.id),
            cantidad: item.cantidad,
            stock: item.producto.stock,
            onChanged: (n) => setState(() {
              item.cantidad = n;
              factura = null;
              mensajeError = "";
            }),
            onExceso: () => _avisar(
              "Stock insuficiente para ${item.producto.nombre}: "
              "solo hay ${item.producto.stock} disponibles",
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: item.cantidad < item.producto.stock
                ? () => agregarAlCarrito(item.producto)
                : null,
          ),
          SizedBox(
            width: 68,
            child: Text(
              "\$${item.subtotal.toStringAsFixed(2)}",
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaTotal(String etiqueta, double valor, {bool grande = false}) {
    final estilo = TextStyle(
      fontSize: grande ? 18 : 14,
      fontWeight: grande ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: estilo),
          Text("\$${valor.toStringAsFixed(2)}", style: estilo),
        ],
      ),
    );
  }

  Widget _panelCarrito() {
    return _panel(
      icono: Icons.shopping_cart_outlined,
      titulo: "Carrito",
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: carrito.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.remove_shopping_cart_outlined,
                            size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("Tu carrito está vacío",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: carrito.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) => _lineaCarrito(carrito[index]),
                  ),
          ),
          const Divider(),
          _filaTotal("Subtotal", subtotal),
          _filaTotal("IVA 15%", iva),
          _filaTotal("Total", total, grande: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: generandoFactura ? null : generarFactura,
                  icon: generandoFactura
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.receipt_long),
                  label: Text(
                    generandoFactura ? "Generando..." : "Generar factura",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: generandoFactura ? null : limpiarCarrito,
                icon: const Icon(Icons.delete_outline),
                tooltip: "Limpiar carrito",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panelFactura() {
    final f = factura;
    return _panel(
      icono: Icons.receipt_long,
      titulo: "Factura",
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mensajeError.isNotEmpty && productos.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                mensajeError.replaceFirst("Exception: ", ""),
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          if (f != null)
            Align(
              alignment: Alignment.centerRight,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text("Ticket")),
                  ButtonSegment(value: true, label: Text("XML")),
                ],
                selected: {verXml},
                onSelectionChanged: (v) => setState(() => verXml = v.first),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: f == null
                ? const Center(
                    child: Text(
                      "Aquí aparecerá el ticket\nde la factura generada.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : SingleChildScrollView(
                    child: verXml
                        ? SelectableText(
                            f.xml,
                            style: const TextStyle(
                              fontFamily: "monospace",
                              fontSize: 12,
                            ),
                          )
                        : TicketFactura(factura: f),
                  ),
          ),
        ],
      ),
    );
  }
}
