Genera un payload JSON contable con estructura estandarizada para integrar los movimientos de ventas diarias hacia un ERP, sistema financiero o middleware de contabilidad.
El diseño está orientado a flujos modernos de integración por API REST, manteniendo una separación clara entre encabezado transaccional, metadatos operativos y partidas contables.


USE [ERP_Analytics]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/**********************************************************************************************
 Autor:         Aleman Paez Mauricio
 Fecha:         2024-09-30
 Descripción:   Genera un JSON estructurado con el formato del endpoint de SAP Business One
                (/JournalEntries), consolidando las ventas diarias y agrupándolas por método
                de pago y centro de costo. Ideal para integraciones contables automáticas.

 Parámetros:
   @Fecha DATE       → Fecha de corte de las ventas
***********************************************************************************************/

ALTER PROCEDURE [dbo].[sp_Generate_SAP_Journal_JSON]
    @Fecha DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @JsonHeader NVARCHAR(MAX),
        @JsonLines NVARCHAR(MAX) = '',
        @JsonOutput NVARCHAR(MAX),
        @MetodoPago NVARCHAR(50),
        @CentroCosto NVARCHAR(50),
        @Subtotal MONEY,
        @IVA MONEY,
        @Total MONEY,
        @AccountDebit NVARCHAR(10),
        @AccountCredit NVARCHAR(10),
        @AnalyticCode NVARCHAR(10);

    IF OBJECT_ID('tempdb..#Ventas') IS NOT NULL DROP TABLE #Ventas;

    CREATE TABLE #Ventas (
        MetodoPago NVARCHAR(50),
        CentroCosto NVARCHAR(50),
        Subtotal MONEY,
        IVA MONEY,
        Total MONEY
    );

    INSERT INTO #Ventas (MetodoPago, CentroCosto, Subtotal, IVA, Total)
    VALUES
        ('Efectivo', 'LOG01', 12000, 1920, 13920),
        ('Tarjeta',  'LOG01', 8000, 1280, 9280),
        ('Transferencia', 'ADM02', 5000, 800, 5800);

  
    SET @JsonHeader = 
    '{' +
        '"Memo": "Asiento de ventas del ' + CONVERT(VARCHAR(10), @Fecha, 120) + '",' +
        '"ReferenceDate": "' + CONVERT(VARCHAR(10), @Fecha, 120) + '",' +
        '"JournalEntryLines": [';

    DECLARE Ventas_Cursor CURSOR FOR
        SELECT MetodoPago, CentroCosto, Subtotal, IVA, Total
        FROM #Ventas;

    OPEN Ventas_Cursor;
    FETCH NEXT FROM Ventas_Cursor INTO @MetodoPago, @CentroCosto, @Subtotal, @IVA, @Total;

    WHILE @@FETCH_STATUS = 0
    BEGIN
  
        SET @AccountDebit = 
            CASE 
                WHEN @MetodoPago = 'Efectivo' THEN '1101'
                WHEN @MetodoPago = 'Tarjeta' THEN '1102'
                WHEN @MetodoPago = 'Transferencia' THEN '1103'
                ELSE '1199'
            END;

        SET @AccountCredit = '5000'; -- Ventas
        SET @AnalyticCode = @CentroCosto;

        SET @JsonLines = @JsonLines +
            '{' +
                '"AccountCode": "' + @AccountDebit + '",' +
                '"Debit": ' + CAST(@Total AS VARCHAR) + ',' +
                '"Credit": 0.00,' +
                '"ShortName": "' + @MetodoPago + '",' +
                '"CostingCode": "' + @AnalyticCode + '"' +
            '},';

    
        SET @JsonLines = @JsonLines +
            '{' +
                '"AccountCode": "' + @AccountCredit + '",' +
                '"Debit": 0.00,' +
                '"Credit": ' + CAST(@Subtotal AS VARCHAR) + ',' +
                '"ShortName": "Ventas - ' + @CentroCosto + '",' +
                '"CostingCode": "' + @AnalyticCode + '"' +
            '},';

  
        SET @JsonLines = @JsonLines +
            '{' +
                '"AccountCode": "2080",' +
                '"Debit": 0.00,' +
                '"Credit": ' + CAST(@IVA AS VARCHAR) + ',' +
                '"ShortName": "IVA Trasladado",' +
                '"CostingCode": "' + @AnalyticCode + '"' +
            '},';

        FETCH NEXT FROM Ventas_Cursor INTO @MetodoPago, @CentroCosto, @Subtotal, @IVA, @Total;
    END;

    CLOSE Ventas_Cursor;
    DEALLOCATE Ventas_Cursor;

    SET @JsonLines = LEFT(@JsonLines, LEN(@JsonLines) - 1);

    SET @JsonOutput = @JsonHeader + @JsonLines + ']}';
    SELECT @JsonOutput AS [SAP_Journal_JSON];

    DROP TABLE #Ventas;
END;
GO
