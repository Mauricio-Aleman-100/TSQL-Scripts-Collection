En un sistema ERP, la tabla MOVIMIENTOS almacena las entradas y salidas de inventario de cada producto.
Cada fila representa un movimiento con una cantidad (QUANTITY), positiva para entradas y negativa para salidas.

El objetivo es calcular, para cada producto, el stock acumulado a lo largo del tiempo, es decir, un running total que muestre cómo cambia el inventario después de cada movimiento.

-- Eliminamos la tabla si ya existía
DROP TABLE IF EXISTS dbo.MOVIMIENTOS;

-- Creamos la tabla base de movimientos de inventario
CREATE TABLE dbo.MOVIMIENTOS (
    TRANID INT IDENTITY(1,1) PRIMARY KEY,
    PRODUCTID INT NOT NULL,
    TRANSACTIONDATE DATETIME NOT NULL,
    QUANTITY INT NOT NULL
);

-- Insertamos datos de ejemplo
INSERT INTO dbo.MOVIMIENTOS (PRODUCTID, TRANSACTIONDATE, QUANTITY)
VALUES
(101, '2025-01-01',  10),
(101, '2025-01-03',  -3),
(101, '2025-01-05',   5),
(102, '2025-01-02',   7),
(102, '2025-01-04',  -2),
(102, '2025-01-06',   8),
(103, '2025-01-01',   4),
(103, '2025-01-02',  -1);


---- VERSIÓN CON CURSOR

DECLARE
    @TRANID INT,
    @PREVPRODUCTID INT,
    @PRODUCTID INT,
    @TRANSACTIONDATE DATETIME,
    @QUANTITY INT,
    @TOTAL INT;

DECLARE @RESULT TABLE (
    TRANID INT,
    PRODUCTID INT,
    TRANSACTIONDATE DATETIME,
    QUANTITY INT,
    TOTAL INT
);

DECLARE C CURSOR FAST_FORWARD FOR
    SELECT TRANID, PRODUCTID, TRANSACTIONDATE, QUANTITY
    FROM DBO.MOVIMIENTOS
    ORDER BY PRODUCTID, TRANID;

OPEN C;

FETCH NEXT FROM C INTO @TRANID, @PRODUCTID, @TRANSACTIONDATE, @QUANTITY;
SELECT @PREVPRODUCTID = @PRODUCTID, @TOTAL = 0;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @PRODUCTID <> @PREVPRODUCTID
        SELECT @PREVPRODUCTID = @PRODUCTID, @TOTAL = 0;

    SET @TOTAL = @TOTAL + @QUANTITY;

    INSERT INTO @RESULT VALUES (@TRANID, @PRODUCTID, @TRANSACTIONDATE, @QUANTITY, @TOTAL);

    FETCH NEXT FROM C INTO @TRANID, @PRODUCTID, @TRANSACTIONDATE, @QUANTITY;
END

CLOSE C;
DEALLOCATE C;

SELECT * FROM @RESULT ORDER BY PRODUCTID, TRANID;

****************************************************
OPTIMIZACIÓN CON FUNCIÓN OVER()
****************************************************
SELECT 
    TRANID,
    PRODUCTID,
    TRANSACTIONDATE,
    QUANTITY,
    SUM(QUANTITY) OVER (PARTITION BY PRODUCTID ORDER BY TRANID) AS TOTAL
FROM dbo.MOVIMIENTOS
ORDER BY PRODUCTID, TRANID;


