USE MASTER;
GO

-- 1. Crear base de datos de ejemplo
CREATE DATABASE VentasCorporacion
ON PRIMARY
(NAME = VentasCorpData, FILENAME = 'C:\Data\VentasCorpData.mdf',
 SIZE = 50MB, FILEGROWTH = 25%)
LOG ON
(NAME = VentasCorpLog, FILENAME = 'C:\Data\VentasCorpLog.ldf',
 SIZE = 25MB, FILEGROWTH = 25%);
GO

-- 2. Crear filegroups adicionales para particionar
ALTER DATABASE VentasCorporacion ADD FILEGROUP VentasParte1;
ALTER DATABASE VentasCorporacion ADD FILEGROUP VentasParte2;
ALTER DATABASE VentasCorporacion ADD FILEGROUP VentasParte3;
GO

-- 3. Agregar archivos a cada filegroup
ALTER DATABASE VentasCorporacion
ADD FILE (NAME = Ventas1, FILENAME = 'C:\Data\Ventas1.ndf', SIZE=50MB, FILEGROWTH=25%) 
TO FILEGROUP VentasParte1;

ALTER DATABASE VentasCorporacion
ADD FILE (NAME = Ventas2, FILENAME = 'C:\Data\Ventas2.ndf', SIZE=50MB, FILEGROWTH=25%) 
TO FILEGROUP VentasParte2;

ALTER DATABASE VentasCorporacion
ADD FILE (NAME = Ventas3, FILENAME = 'C:\Data\Ventas3.ndf', SIZE=50MB, FILEGROWTH=25%) 
TO FILEGROUP VentasParte3;
GO

-- 4. Crear la función de partición (por rangos de ID_Venta)
USE VentasCorporacion;
GO

CREATE PARTITION FUNCTION PF_Ventas (BIGINT)
AS RANGE LEFT FOR VALUES (1000, 2000);
GO

-- 5. Crear el esquema de partición
CREATE PARTITION SCHEME PS_Ventas
AS PARTITION PF_Ventas
TO (VentasParte1, VentasParte2, VentasParte3);
GO

-- 6. Crear la tabla particionada
CREATE TABLE Ventas
(
    ID_Venta BIGINT NOT NULL PRIMARY KEY,
    Fecha DATETIME NOT NULL,
    ID_Cliente BIGINT NOT NULL,
    Monto MONEY NOT NULL
) ON PS_Ventas(ID_Venta);
GO

-- 7. Insertar datos de prueba
INSERT INTO Ventas (ID_Venta, Fecha, ID_Cliente, Monto)
VALUES
(1, '2025-01-15', 101, 250.50),
(500, '2025-02-10', 102, 180.00),
(1200, '2025-03-05', 103, 300.75),
(1500, '2025-03-20', 104, 420.10),
(2100, '2025-04-01', 105, 150.25),
(2500, '2025-04-15', 106, 520.00);
GO

-- 8. Consultar la partición de cada venta
SELECT ID_Venta, Fecha, ID_Cliente, Monto, 
       $PARTITION.PF_Ventas(ID_Venta) AS Particion
FROM Ventas
ORDER BY ID_Venta;
GO

-- 9. Crear índice no clusterizado particionado
CREATE NONCLUSTERED INDEX IDX_Ventas_Fecha
ON Ventas(Fecha)
ON PS_Ventas(ID_Venta);
GO

-- 10. Agregar un nuevo filegroup y extender partición
ALTER DATABASE VentasCorporacion ADD FILEGROUP VentasParte4;
ALTER DATABASE VentasCorporacion
ADD FILE (NAME = Ventas4, FILENAME = 'C:\Data\Ventas4.ndf', SIZE=50MB, FILEGROWTH=25%) 
TO FILEGROUP VentasParte4;

ALTER PARTITION SCHEME PS_Ventas NEXT USED VentasParte4;
ALTER PARTITION FUNCTION PF_Ventas() SPLIT RANGE (3000);
GO
