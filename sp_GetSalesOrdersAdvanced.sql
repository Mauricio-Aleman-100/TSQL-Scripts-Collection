USE BI;
GO

Description:   Devuelve detalles de órdenes de venta

filtrando por SalesOrderIDs, fechas y productos opcionalmente.

CREATE OR ALTER PROCEDURE dbo.sp_GetSalesOrdersAdvanced
    @SalesOrderIDs NVARCHAR(MAX),        -- Lista CSV de SalesOrderID
    @StartDate DATE = NULL,              -- Fecha inicial opcional
    @EndDate DATE = NULL,                -- Fecha final opcional
    @ProductIDs NVARCHAR(MAX) = NULL     -- Lista CSV opcional de ProductID
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validación de SalesOrderIDs
        IF @SalesOrderIDs IS NULL OR LTRIM(RTRIM(@SalesOrderIDs)) = ''
        BEGIN
            RAISERROR('La lista de SalesOrderIDs no puede estar vacía.',16,1);
            RETURN;
        END

        -- Transformar SalesOrderIDs en tabla
        DECLARE @IDs TABLE (ID INT);
        INSERT INTO @IDs(ID)
        SELECT TRY_CAST(value AS INT)
        FROM STRING_SPLIT(@SalesOrderIDs, ',')
        WHERE TRY_CAST(value AS INT) IS NOT NULL;

        IF NOT EXISTS(SELECT 1 FROM @IDs)
        BEGIN
            RAISERROR('No se encontraron SalesOrderIDs válidos en la lista.',16,1);
            RETURN;
        END

        -- Transformar ProductIDs en tabla (si se pasan)
        DECLARE @PIDs TABLE (ID INT);
        IF @ProductIDs IS NOT NULL AND LTRIM(RTRIM(@ProductIDs)) <> ''
        BEGIN
            INSERT INTO @PIDs(ID)
            SELECT TRY_CAST(value AS INT)
            FROM STRING_SPLIT(@ProductIDs, ',')
            WHERE TRY_CAST(value AS INT) IS NOT NULL;
        END

        -- Consulta principal
        SELECT 
            SOH.SalesOrderID,
            SOH.OrderDate,
            SOD.SalesOrderDetailID,
            SOD.ProductID,
            P.Name AS ProductName,
            SOD.OrderQty,
            SOD.UnitPrice,
            SOD.LineTotal
        FROM Sales.SalesOrderHeader SOH
        INNER JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
        INNER JOIN Production.Product P ON SOD.ProductID = P.ProductID
        WHERE SOH.SalesOrderID IN (SELECT ID FROM @IDs)
          AND (@StartDate IS NULL OR SOH.OrderDate >= @StartDate)
          AND (@EndDate IS NULL OR SOH.OrderDate <= @EndDate)
          AND (@ProductIDs IS NULL OR SOD.ProductID IN (SELECT ID FROM @PIDs))
        ORDER BY SOH.SalesOrderID, SOD.SalesOrderDetailID;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMsg NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMsg = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR('Error en sp_GetSalesOrdersAdvanced: %s', @ErrorSeverity, @ErrorState, @ErrorMsg);
    END CATCH
END
GO
