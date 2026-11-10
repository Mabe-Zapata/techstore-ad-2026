# TechStore Facturación

Práctica SOA: API REST en Flask con SQL Server y una app Flutter de carrito de compras que genera facturas (ticket + XML) con control de stock y concurrencia.

## Contenido

- [Arquitectura](#arquitectura)
- [Requisitos](#requisitos)
- [Puesta en marcha](#puesta-en-marcha)
- [API](#api)
- [Control de stock y concurrencia](#control-de-stock-y-concurrencia)
- [App Flutter](#app-flutter)
- [Estructura de carpetas](#estructura-de-carpetas)
- [Pruebas](#pruebas)

## Arquitectura

```
Flutter (carrito)  ──HTTP/JSON──▶  Flask API  ──pyodbc──▶  SQL Server
 lib/pages, widgets                controllers → models/data   AppDistribuidas_2026_DB
```

## Requisitos

- Python 3.10+
- SQL Server y [ODBC Driver 18 for SQL Server](https://learn.microsoft.com/sql/connect/odbc/download-odbc-driver-for-sql-server)
- Flutter SDK (Dart ^3.13)

## Puesta en marcha

### 1. Base de datos

La base `AppDistribuidas_2026_DB` debe tener la tabla `dbo.PRODUCTOS` (`ID` PK, `NOMBRE`, `PRECIO`, `STOCK`). Ejecuta en orden:

| Script | Qué hace |
| --- | --- |
| `sql/techstore.sql` | Agrega `IMAGENURL` a `PRODUCTOS` y crea `FACTURAS` y `FACTURA_DETALLE` |
| `sql/02_productos_tecnologia.sql` | Inserta 10 productos de tecnología con imagen (datos de prueba) |

Ambos son idempotentes: se pueden volver a ejecutar sin duplicar datos.

### 2. Conexión

Edita `data/db.py` con tu servidor y credenciales:

```python
DB_SERVER = r"localhost\MSSQLSERVER01"   # instancia con nombre; usa "localhost" si es la predeterminada
DB_NAME = "AppDistribuidas_2026_DB"
DB_USER = "sa"
DB_PASSWORD = "..."
```

> **No subas contraseñas reales a un repositorio público.** Para producción usa variables de entorno.

### 3. Backend

```bash
pip install -r requirements.txt
python app.py          # http://localhost:5000
```

### 4. Frontend

```bash
cd flutter/techstore_carrito
flutter pub get
flutter run -d chrome  # también: -d windows
```

La app usa `http://localhost:5000`, o `http://10.0.2.2:5000` en el emulador de Android (`lib/services/api_service.dart`).

## API

### `GET /api/productos`

Lista los productos con su stock actual.

```json
[{ "id": 4, "nombre": "Laptop Pro 14", "precio": 1299.99, "stock": 10, "imagenUrl": "https://..." }]
```

### `POST /api/facturas`

```json
{
  "factura": { "numero": "F001-1", "fecha": "2026-11-09" },
  "cliente": { "nombre": "Juan Perez", "cedula_ruc": "1234567890" },
  "detalles": [{ "producto_id": 4, "cantidad": 2 }]
}
```

El nombre y el precio se toman de la base de datos, no del cliente. `cantidad` debe ser un entero mayor que cero.

| Código | Significado |
| --- | --- |
| `200` | Factura generada. Devuelve `factura`, `totales` (subtotal, IVA 15 %, total) y `xml` |
| `400` | Datos inválidos (lista `errores` por campo) |
| `409` | Conflicto. `codigo: "STOCK_INSUFICIENTE"` si no hay stock; `"CONFLICTO"` si la factura ya existe o el producto no existe |

## Control de stock y concurrencia

La factura, su detalle, el XML y el descuento de stock se guardan en **una sola transacción**: si algo falla, no queda nada a medias.

El descuento es atómico:

```sql
UPDATE dbo.PRODUCTOS SET STOCK = STOCK - @n WHERE ID = @id AND STOCK >= @n
```

SQL Server bloquea la fila, así que con 80 unidades y dos compras de 50 simultáneas, la primera pasa (quedan 30) y la segunda afecta 0 filas, hace rollback y recibe un `409`. Los productos se procesan en orden de `ID` para evitar deadlocks.

## App Flutter

- Catálogo en grilla con imagen, precio, chip de stock y buscador.
- Carrito con botones − / + y cantidad editable: al tocar el número se convierte en un campo que **solo acepta dígitos** y limita al stock disponible, avisando abajo.
- La factura se muestra como **ticket**, con opción de ver el **XML**.
- Si otro cliente agota el stock antes, aparece una alerta "Stock no disponible" y el carrito se actualiza con el stock real.

## Estructura de carpetas

```
app.py                    # Composición: registra los blueprints
controllers/              # HTTP: valida la petición y responde
  factura_controller.py
  producto_controller.py
models/factura_model.py   # Validación y generación del XML
data/                     # Acceso a SQL Server
  db.py                   # Cadena de conexión
  factura_data.py         # Transacción de factura + stock
  productos_data.py
sql/                      # Scripts de migración
flutter/techstore_carrito/
  lib/models/             # Producto, ItemCarrito, Factura
  lib/pages/              # CarritoPage
  lib/services/           # ApiService
  lib/widgets/            # TicketFactura, CantidadField, alerta de stock
  test/
```

## Pruebas

```bash
cd flutter/techstore_carrito
flutter test test/cantidad_field_test.dart test/alerta_stock_test.dart
```

`test/widget_test.dart` es la plantilla por defecto de Flutter y está desactualizada.
