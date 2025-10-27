Este proyecto muestra cómo implementar procedimientos almacenados (Stored Procedures) en SQL Server dentro de un entorno empresarial de una farmacéutica, aplicando las mejores prácticas de programación T-SQL.

USE FarmaDB;
GO

CREATE PROCEDURE CHECK_LOTES
AS
DECLARE @lote INT = 0;
WHILE (@lote <= 10)
BEGIN
    IF (@lote % 2 = 0)
        PRINT CAST(@lote AS VARCHAR(10)) + ' → Lote verificado: número par';
    ELSE
        PRINT CAST(@lote AS VARCHAR(10)) + ' → Lote verificado: número impar';
    SET @lote = @lote + 1;
END;
GO

-- Ejecutar
EXEC CHECK_LOTES;
GO

CREATE PROCEDURE INSERT_SUPPLIER (
    @SupplierName   VARCHAR(150),
    @ContactName    VARCHAR(150),
    @ContactTitle   VARCHAR(150),
    @Country        VARCHAR(100)
)
AS
INSERT INTO Suppliers (SupplierName, ContactName, ContactTitle, Country)
VALUES (@SupplierName, @ContactName, @ContactTitle, @Country);
GO

ALTER PROCEDURE INSERT_SUPPLIER (
    @SupplierName   VARCHAR(150),
    @ContactName    VARCHAR(150),
    @ContactTitle   VARCHAR(150),
    @Country        VARCHAR(100),
    @Address        VARCHAR(200)
)
AS
INSERT INTO Suppliers (SupplierName, ContactName, ContactTitle, Country, Address)
VALUES (@SupplierName, @ContactName, @ContactTitle, @Country, @Address);
GO

EXEC INSERT_SUPPLIER 
    'Laboratorios Vida',
    'Ana López',
    'Gerente Comercial',
    'México',
    'Av. de la Salud 123, CDMX';
GO

-- Verificar inserción
SELECT * FROM Suppliers WHERE SupplierName = 'Laboratorios Vida';
GO
SELECT * FROM sys.procedures;
GO

EXEC sp_helptext INSERT_SUPPLIER;
GO

EXEC INSERT_SUPPLIER 
    'Farmacéutica Global',
    'Carlos Martínez',
    'Director de Compras',
    'Guatemala',
    'Zona 10, Ciudad de Guatemala'
WITH RECOMPILE;
GO

CREATE PROCEDURE DELETE_SUPPLIERS_BY_COUNTRY (
    @Country VARCHAR(100),
    @RowsAffected INT OUTPUT
)
AS
DELETE FROM Suppliers WHERE Country = @Country;
SET @RowsAffected = @@ROWCOUNT;
GO

-- Uso del procedimiento con parámetro OUTPUT
DECLARE @Deleted INT;
EXEC DELETE_SUPPLIERS_BY_COUNTRY 'Guatemala', @Deleted OUTPUT;
SELECT @Deleted AS 'Proveedores Eliminados';
GO

DROP PROCEDURE INSERT_SUPPLIER;
GO
CREATE PROCEDURE PROC_VENTAS
WITH ENCRYPTION, RECOMPILE
AS
SELECT 
    p.PatientID,
    p.FirstName + ' ' + p.LastName AS Paciente,
    p.Country AS País,
    pr.PrescriptionID,
    pr.PrescriptionDate AS FechaVenta,
    m.MedicationName AS Medicamento,
    m.Category AS Categoría,
    d.Quantity AS Cantidad,
    d.UnitPrice AS PrecioUnitario,
    (d.Quantity * d.UnitPrice) AS Total
FROM Patients AS p
INNER JOIN Prescriptions AS pr ON p.PatientID = pr.PatientID
INNER JOIN PrescriptionDetails AS d ON pr.PrescriptionID = d.PrescriptionID
INNER JOIN Medications AS m ON m.MedicationID = d.MedicationID;
GO

-- Ejecutar el procedimiento
EXEC PROC_VENTAS;
GO

ALTER PROCEDURE PROC_VENTAS
WITH ENCRYPTION
AS
SELECT 
    p.PatientID,
    p.FirstName + ' ' + p.LastName AS Paciente,
    p.Country AS País,
    pr.PrescriptionID,
    pr.PrescriptionDate AS FechaVenta,
    m.MedicationName AS Medicamento,
    m.Category AS Categoría,
    d.Quantity AS Cantidad,
    d.UnitPrice AS PrecioUnitario,
    (d.Quantity * d.UnitPrice) AS Total
FROM Patients AS p
INNER JOIN Prescriptions AS pr ON p.PatientID = pr.PatientID
INNER JOIN PrescriptionDetails AS d ON pr.PrescriptionID = d.PrescriptionID
INNER JOIN Medications AS m ON m.MedicationID = d.MedicationID;
GO
EXEC PROC_VENTAS WITH RECOMPILE;
GO
