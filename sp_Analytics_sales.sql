USE [Analytics]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*****************************************************************************************
-- PROCEDURE: rpt_Analytics_VentasPorItemAgregado
-- AUTOR:     Aleman Paez Mauricio
-- PROPÓSITO:
--   Consolidar las ventas de productos desde dos bases de datos (actual e histórica)
--   en un único reporte que muestre las cantidades vendidas, el costo consolidado
--   y los ingresos brutos por producto en un rango de fechas.
--
-- CONTEXTO:
--   Escenario práctico de migración de ERP: la base antigua (LEGACY_DB) conserva
--   ventas previas a 2025 y la nueva base (CURRENT_DB) almacena las actuales.
--
-- PARÁMETROS:
--   @FechaIni   -> Fecha de inicio del periodo
--   @FechaEnd   -> Fecha de fin del periodo
--
-- SALIDA:
--   ItemCode, ItemName, TotalQuantity, ConsolidatedCost, ConsolidatedRevenue

*****************************************************************************************/

ALTER PROCEDURE [dbo].[rpt_Analytics_VentasPorItemAgregado] 
    @FechaIni DATE,
    @FechaEnd DATE
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------------------------
    -- 1. Transacciones de la base actual (CURRENT_DB)
    ---------------------------------------------------------------------------
    SELECT  
        P.SKU_Code AS ItemCode,
        PT.Description AS ItemName,
        TR.Quantity_Shipped AS Quantity,
        ISNULL(TR.Unit_Cost * TR.Quantity_Shipped, 0) AS TotalCost,  -- Costo total
        ISNULL(TR.Gross_Revenue, 0) AS GrossRevenue
    INTO #CurrentTransactions_TEMP
    FROM [CURRENT_DB]..Transaction_Line AS TR
    INNER JOIN [CURRENT_DB]..Sales_Order AS SO ON SO.Order_ID = TR.Order_ID
    LEFT JOIN [CURRENT_DB]..Product_Catalog AS P ON P.Product_ID = TR.Product_ID
    LEFT JOIN [CURRENT_DB]..Product_Template AS PT ON P.Template_ID = PT.Template_ID
    WHERE SO.Status <> 'VOID'
      AND CONVERT(DATE, DATEADD(HOUR, -6, SO.Transaction_Date)) BETWEEN @FechaIni AND @FechaEnd;

    ---------------------------------------------------------------------------
    -- 2. Transacciones de la base histórica (LEGACY_DB)
    --    En esta base, Unit_Cost representa el costo unitario, por lo tanto
    --    se multiplicará más adelante para equiparar con la base actual.
    ---------------------------------------------------------------------------
    SELECT  
        P.SKU_Code AS ItemCode,
        PT.Description AS ItemName,
        TR.Quantity_Shipped AS Quantity,
        ISNULL(TR.Unit_Cost, 0) AS UnitCost,  -- Aquí solo guardamos el costo unitario
        ISNULL(TR.Gross_Revenue, 0) AS GrossRevenue
    INTO #HistoricalTransactions_TEMP
    FROM [LEGACY_DB]..Transaction_Line AS TR
    INNER JOIN [LEGACY_DB]..Sales_Order AS SO ON SO.Order_ID = TR.Order_ID
    LEFT JOIN [LEGACY_DB]..Product_Catalog AS P ON P.Product_ID = TR.Product_ID
    LEFT JOIN [LEGACY_DB]..Product_Template AS PT ON P.Template_ID = PT.Template_ID
    WHERE SO.Status <> 'VOID'
      AND CONVERT(DATE, DATEADD(HOUR, -6, SO.Transaction_Date)) BETWEEN @FechaIni AND @FechaEnd;

    ---------------------------------------------------------------------------
    -- 3. Unión y consolidación de ambas fuentes
    ---------------------------------------------------------------------------
    SELECT  
        ItemCode,
        ItemName,
        SUM(Quantity) AS TotalQuantity,
        SUM(TotalCost) AS ConsolidatedCost,
        SUM(GrossRevenue) AS ConsolidatedRevenue
    FROM (
        -- Fuente actual
        SELECT 
            ItemCode, 
            ItemName, 
            Quantity, 
            TotalCost, 
            GrossRevenue
        FROM #CurrentTransactions_TEMP

        UNION ALL

       
        SELECT 
            ItemCode, 
            ItemName, 
            Quantity, 
            (UnitCost * Quantity) AS TotalCost, 
            GrossRevenue
        FROM #HistoricalTransactions_TEMP
    ) AS Consolidated
    GROUP BY ItemCode, ItemName
    ORDER BY ItemName;

    ---------------------------------------------------------------------------
    -- 4. Limpieza temporal
    ---------------------------------------------------------------------------
    DROP TABLE #CurrentTransactions_TEMP;
    DROP TABLE #HistoricalTransactions_TEMP;
END
GO
