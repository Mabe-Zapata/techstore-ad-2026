-- Datos de prueba: productos de tecnologia con imagen (idempotente: no duplica por NOMBRE).
-- NOMBRE es VARCHAR, por eso sin tildes.
USE AppDistribuidas_2026_DB;
GO

DECLARE @img NVARCHAR(100) = N'https://images.unsplash.com/photo-';
DECLARE @q   NVARCHAR(20)  = N'?w=400&q=70';

INSERT INTO dbo.PRODUCTOS (NOMBRE, PRECIO, STOCK, IMAGENURL)
SELECT v.NOMBRE, v.PRECIO, v.STOCK, @img + v.FOTO + @q
FROM (VALUES
    ('Laptop Pro 14',           1299.99, 10, N'1496181133206-80ce9b88a853'),
    ('Ultrabook Slim 13',        999.00,  8, N'1593642632823-8f785ba67e45'),
    ('Audifonos Bluetooth',      149.90, 25, N'1505740420928-5e560c06d30e'),
    ('Smartphone X',             799.00, 15, N'1511707171634-5f897ff02aa9'),
    ('Monitor 24 pulgadas',      229.50, 12, N'1527443224154-c4a3942d3acf'),
    ('Mouse Inalambrico',         24.99, 40, N'1527864550417-7fd91fc51a46'),
    ('Smartwatch Serie 5',       249.00, 18, N'1546868871-7041f2a55e12'),
    ('Tablet 11 pulgadas',       429.00, 14, N'1585790050230-5dd28404ccb9'),
    ('Teclado Inalambrico',       59.90, 30, N'1587829741301-dc798b83add3'),
    ('Teclado Mecanico Compacto', 89.00, 20, N'1625948515291-69613efd103f')
) AS v(NOMBRE, PRECIO, STOCK, FOTO)
WHERE NOT EXISTS (SELECT 1 FROM dbo.PRODUCTOS p WHERE p.NOMBRE = v.NOMBRE);
GO
