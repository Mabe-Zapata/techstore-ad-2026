import 'package:flutter/material.dart';
import 'pages/carrito_page.dart';
void main() {
runApp(const TechStoreApp());
}
class TechStoreApp extends StatelessWidget {
const TechStoreApp({super.key});
@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'TechStore 360',
debugShowCheckedModeBanner: false,
theme: ThemeData(
useMaterial3: true,
colorSchemeSeed: Colors.indigo,
),
home: const CarritoPage(),
);
}
}