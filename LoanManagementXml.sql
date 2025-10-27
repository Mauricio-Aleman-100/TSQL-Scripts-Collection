Gestión de Préstamos Empresariales con XML en SQL Server.
Caso de uso:
Una empresa financiera llamada Finanzas ProActiva gestiona préstamos para pequeñas y medianas empresas (PYMEs).
Cada préstamo tiene detalles asociados, como el monto, tasa de interés, plazo y pagos realizados.
La empresa necesita almacenar y consultar esta información en formato XML dentro de SQL Server, para poder integrarse fácilmente con sistemas de análisis o plataformas externas.


USE Northwind;
GO
SELECT 
    c.CompanyName AS Cliente, 
    o.OrderID AS PrestamoID, 
    o.Freight AS Monto
FROM Customers AS c 
INNER JOIN Orders AS o ON c.CustomerID = o.CustomerID
FOR XML AUTO;
GO

SELECT 
    c.CompanyName AS [Cliente/Nombre],
    o.OrderID AS [Cliente/Prestamo/ID],
    o.Freight AS [Cliente/Prestamo/Monto],
    o.OrderDate AS [Cliente/Prestamo/Fecha]
FROM Customers AS c 
INNER JOIN Orders AS o ON c.CustomerID = o.CustomerID
FOR XML PATH('CarteraDePrestamos');
GO

SELECT 
    c.CompanyName AS Cliente, 
    o.OrderID AS PrestamoID, 
    o.Freight AS Monto
FROM Customers AS c 
INNER JOIN Orders AS o ON c.CustomerID = o.CustomerID
FOR XML RAW('Prestamo'), ROOT('Cartera');
GO

SELECT 
    1 AS Tag, 
    NULL AS Parent,
    c.CustomerID AS [Cliente!1!ID], 
    c.ContactName AS [Cliente!1!Nombre],
    NULL AS [Prestamo!2!ID], 
    NULL AS [Prestamo!2!Monto]
FROM Customers AS c
WHERE c.CustomerID = 'ALFKI'

UNION ALL

SELECT 
    2 AS Tag, 
    1 AS Parent,
    c.CustomerID, 
    c.ContactName, 
    o.OrderID, 
    o.Freight
FROM Customers AS c
INNER JOIN Orders AS o ON c.CustomerID = o.CustomerID
WHERE c.CustomerID = 'ALFKI'
FOR XML EXPLICIT;
GO
ALTER TABLE Orders
ADD DetallesPrestamo XML;
GO
SELECT 
    o.OrderID AS PrestamoID,
    o.OrderDate AS FechaApertura, 
    d.ProductID AS PagoID, 
    d.UnitPrice AS MontoPago, 
    d.Quantity AS NoPago
FROM Orders AS o
INNER JOIN [Order Details] AS d ON o.OrderID = d.OrderID;
GO
UPDATE o
SET o.DetallesPrestamo =
(
    SELECT 
        d.OrderID AS [@PrestamoID],
        p.ProductName AS [ConceptoPago],
        d.UnitPrice AS [MontoPago],
        d.Quantity AS [NumeroPago],
        d.Discount AS [Descuento]
    FROM [Order Details] AS d
    INNER JOIN Products AS p ON d.ProductID = p.ProductID
    WHERE o.OrderID = d.OrderID
    FOR XML PATH('Pago'), ROOT('HistorialPagos')
)
FROM Orders AS o
INNER JOIN [Order Details] AS d ON o.OrderID = d.OrderID;
GO

SELECT 
    o.OrderID AS PrestamoID,
    o.OrderDate AS Fecha,
    c.CompanyName AS Cliente,
    o.DetallesPrestamo AS [Historial_XML]
FROM Orders AS o
INNER JOIN Customers AS c ON o.CustomerID = c.CustomerID;
GO
