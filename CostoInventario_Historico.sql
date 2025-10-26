Proyecto: Evaluación de Costo de Inventario a una Fecha Histórica

Propósito:
Este procedimiento almacenado permite obtener el valor total del inventario (por producto, categoría y almacén) evaluado a una fecha anterior, considerando la última compra efectiva antes de esa fecha.
Es ideal para auditorías contables, análisis de costos FIFO históricos o cierres financieros retroactivos.

Contexto empresarial:
En entornos ERP (SAP, Odoo o Dynamics), los costos de inventario pueden cambiar con el tiempo. 
Este SP reconstruye el costo de cada producto según su última compra registrada antes de una fecha de corte, y estima el valor total del inventario de ese día.

USE [Analytics];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE [dbo].[rpt_Evaluacion_CostoInventario_Historico]
    @FechaCorte DATE,
    @Almacen NVARCHAR(100) = 'WR/Stock'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        PT.Name AS NombreProducto,
        LTRIM(RTRIM(PT.Default_Code)) AS NumeroParte,
        PC.Name AS Categoria,
        SL.Complete_Name AS Almacen,
        SQ.Quantity AS Stock,
        UC.UltimaOrdenCompra,
        DATEADD(HOUR, -6, UC.FechaCompra) AS FechaUltimaCompra,
        ISNULL(UC.CostoUnitario, PT.Virtual_Cost) AS CostoUnitarioFinal,
        (SQ.Quantity * ISNULL(UC.CostoUnitario, PT.Virtual_Cost)) AS CostoTotalEstimado
    FROM dbo.Stock_Quant SQ
    INNER JOIN dbo.Stock_Location SL ON SQ.Location_ID = SL.ID
    LEFT JOIN dbo.Product_Product PP ON SQ.Product_ID = PP.ID
    LEFT JOIN dbo.Product_Template PT ON PP.Product_Tmpl_ID = PT.ID
    LEFT JOIN dbo.Product_Category PC ON PT.Categ_ID = PC.ID
    OUTER APPLY (
        SELECT TOP 1
            PO.Name AS UltimaOrdenCompra,
            PO.Effective_Date AS FechaCompra,
            POL.Price_Unit AS CostoUnitario
        FROM dbo.Purchase_Order_Line POL
        INNER JOIN dbo.Purchase_Order PO ON POL.Order_ID = PO.ID
        INNER JOIN dbo.Stock_Picking_Type SPT ON PO.Picking_Type_ID = SPT.ID
        WHERE POL.Product_ID = PP.ID
          AND PO.State IN ('purchase', 'done')
          AND SPT.ID = 19
          AND PO.Effective_Date <= @FechaCorte
        ORDER BY PO.Effective_Date DESC
    ) AS UC
    WHERE
        SL.Complete_Name = @Almacen
        AND SQ.Quantity > 0
    ORDER BY
        PT.Name;

END;
GO
