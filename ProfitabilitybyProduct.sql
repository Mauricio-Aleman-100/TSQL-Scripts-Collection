La gerencia de Operaciones y Finanzas necesita un reporte que no solo muestre cada transacción, sino que calcule dos métricas críticas después de cada movimiento y por producto:

Stock Acumulado (Running Stock): El saldo exacto de unidades disponibles en el almacén de ese producto en ese momento.
Ganancia Bruta Acumulada (Cumulative Profit): La suma total de la ganancia generada por ese producto desde el inicio del registro hasta esa transacción específica.
Requisito Adicional (Auditoría): El equipo de BI debe demostrar que la técnica moderna de SUM() OVER() es la más rápida y precisa, por lo que el script se utiliza para validar la precisión de los resultados comparándolos con métodos más antiguos como el CURSOR y la SUBQUERY correlacionada.
En resumen: Se utiliza para un Reporte de Trazabilidad y Validación de Balances Acumulados de Inventario y Finanzas, particionado por producto.

USE DB_BI;
GO

/********************************************************************************************
 Author:       Aleman Paez Mauricio
 Description:  Case Study - Inventory and Profitability Analysis
               Demonstrates three SQL approaches to calculate running stock and profitability
               per product: OVER() window function, CURSOR, and SUBQUERY.
*********************************************************************************************/
DROP TABLE IF EXISTS dbo.MovimientosInventario;

SELECT 
    IDENTITY(INT, 1, 1) AS MovimientoID,
    p.ProductID,
    p.Name AS Producto,
    CAST(DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 30, '2025-09-01') AS DATE) AS FechaMovimiento,
    CASE WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN 'ENTRADA' ELSE 'SALIDA' END AS TipoMovimiento,
    ABS(CHECKSUM(NEWID())) % 15 + 1 AS Cantidad,
    ROUND(ABS(CHECKSUM(NEWID())) % 200 + 50, 2) AS CostoUnitario,
    ROUND(ABS(CHECKSUM(NEWID())) % 300 + 100, 2) AS PrecioUnitario
INTO dbo.MovimientosInventario
FROM Production.Product p
WHERE ProductID < 50;

SELECT 
    MovimientoID,
    ProductID,
    Producto,
    FechaMovimiento,
    TipoMovimiento,
    Cantidad,
    CASE WHEN TipoMovimiento = 'ENTRADA' THEN Cantidad ELSE -Cantidad END AS MovimientoAjustado,
    SUM(CASE WHEN TipoMovimiento = 'ENTRADA' THEN Cantidad ELSE -Cantidad END)
        OVER(PARTITION BY ProductID ORDER BY FechaMovimiento, MovimientoID) AS StockAcumulado,
    ROUND(
        CASE WHEN TipoMovimiento = 'SALIDA'
             THEN (PrecioUnitario - CostoUnitario) * Cantidad ELSE 0 END, 2
    ) AS Ganancia,
    SUM(
        ROUND(CASE WHEN TipoMovimiento = 'SALIDA'
             THEN (PrecioUnitario - CostoUnitario) * Cantidad ELSE 0 END, 2)
    ) OVER(PARTITION BY ProductID ORDER BY FechaMovimiento, MovimientoID) AS GananciaAcumulada
FROM dbo.MovimientosInventario
ORDER BY ProductID, FechaMovimiento;

DECLARE @Resultados TABLE (
    MovimientoID INT,
    ProductID INT,
    Producto NVARCHAR(100),
    FechaMovimiento DATE,
    TipoMovimiento NVARCHAR(10),
    Cantidad INT,
    StockAcumulado INT,
    Ganancia MONEY,
    GananciaAcumulada MONEY
);

DECLARE 
    @MovimientoID INT,
    @ProductoActual INT,
    @ProductoPrevio INT,
    @Producto NVARCHAR(100),
    @Tipo NVARCHAR(10),
    @Cantidad INT,
    @Stock INT = 0,
    @Costo MONEY,
    @Precio MONEY,
    @Ganancia MONEY,
    @GananciaTotal MONEY = 0,
    @Fecha DATE;

DECLARE Mov CURSOR FAST_FORWARD FOR
SELECT MovimientoID, ProductID, Producto, FechaMovimiento, TipoMovimiento, Cantidad, CostoUnitario, PrecioUnitario
FROM dbo.MovimientosInventario
ORDER BY ProductID, FechaMovimiento, MovimientoID;

OPEN Mov;
FETCH NEXT FROM Mov INTO @MovimientoID, @ProductoActual, @Producto, @Fecha, @Tipo, @Cantidad, @Costo, @Precio;

SET @ProductoPrevio = @ProductoActual;
SET @Stock = 0;
SET @GananciaTotal = 0;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @ProductoActual <> @ProductoPrevio
    BEGIN
        SET @ProductoPrevio = @ProductoActual;
        SET @Stock = 0;
        SET @GananciaTotal = 0;
    END;

    IF @Tipo = 'ENTRADA'
        SET @Stock = @Stock + @Cantidad;
    ELSE
        SET @Stock = @Stock - @Cantidad;

    SET @Ganancia = CASE WHEN @Tipo = 'SALIDA' THEN (@Precio - @Costo) * @Cantidad ELSE 0 END;
    SET @GananciaTotal = @GananciaTotal + @Ganancia;

    INSERT INTO @Resultados
    VALUES (@MovimientoID, @ProductoActual, @Producto, @Fecha, @Tipo, @Cantidad, @Stock, @Ganancia, @GananciaTotal);

    FETCH NEXT FROM Mov INTO @MovimientoID, @ProductoActual, @Producto, @Fecha, @Tipo, @Cantidad, @Costo, @Precio;
END;

CLOSE Mov;
DEALLOCATE Mov;

SELECT * FROM @Resultados ORDER BY ProductID, FechaMovimiento;
SELECT 
    A.ProductID,
    A.Producto,
    A.MovimientoID,
    A.FechaMovimiento,
    A.TipoMovimiento,
    A.Cantidad,
    SUM(
        CASE WHEN B.TipoMovimiento = 'ENTRADA' THEN B.Cantidad ELSE -B.Cantidad END
    ) AS StockAcumulado,
    SUM(
        CASE WHEN B.TipoMovimiento = 'SALIDA'
             THEN (B.PrecioUnitario - B.CostoUnitario) * B.Cantidad ELSE 0 END
    ) AS GananciaAcumulada
FROM dbo.MovimientosInventario A
JOIN dbo.MovimientosInventario B
    ON A.ProductID = B.ProductID
   AND B.MovimientoID <= A.MovimientoID
GROUP BY 
    A.ProductID, A.Producto, A.MovimientoID, A.FechaMovimiento, A.TipoMovimiento, A.Cantidad
ORDER BY A.ProductID, A.FechaMovimiento;
