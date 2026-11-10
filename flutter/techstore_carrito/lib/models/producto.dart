class Producto{
  final int id;
  final String nombre;
  final double precio;
  final int stock;
  final String imagenUrl;

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
    required this.imagenUrl
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      nombre: json['nombre'],
      precio: json['precio'].toDouble(),
      stock: json['stock'],
      imagenUrl: json['imagenUrl'] ?? "",
    );
  }
}

