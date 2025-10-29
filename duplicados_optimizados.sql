En un sistema de ventas o CRM, la tabla CLIENTES puede acumular duplicados debido a errores de importación o sincronización (por ejemplo, varios registros con el mismo nombre y correo).

El objetivo es eliminar los duplicados, conservando solo el registro más reciente por cliente, de manera segura, dentro de una transacción que permita revertir si algo sale mal.


DROP TABLE IF EXISTS dbo.CLIENTES;

CREATE TABLE dbo.CLIENTES (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    NOMBRE NVARCHAR(100),
    EMAIL NVARCHAR(100),
    FECHA_REGISTRO DATETIME
);

-- Insertamos algunos datos con duplicados
INSERT INTO dbo.CLIENTES (NOMBRE, EMAIL, FECHA_REGISTRO)
VALUES
('Juan Pérez', 'juan@example.com', '2025-01-01'),
('Juan Pérez', 'juan@example.com', '2025-02-01'), -- duplicado más reciente
('Ana López', 'ana@example.com', '2025-01-05'),
('Ana López', 'ana@example.com', '2025-01-07'),   -- duplicado
('Carlos Ruiz', 'carlos@example.com', '2025-03-01');


-----VARIANTE SIN USAR OVER()
BEGIN TRAN;

BEGIN TRY
    DELETE FROM dbo.CLIENTES
    WHERE ID NOT IN (
        SELECT MAX(ID)
        FROM dbo.CLIENTES
        GROUP BY EMAIL
    );

    COMMIT TRAN;
    PRINT 'Duplicados eliminados correctamente.';
END TRY
BEGIN CATCH
    ROLLBACK TRAN;
    PRINT 'Error, cambios revertidos.';
END CATCH;




BEGIN TRAN;

BEGIN TRY
    -- Usamos una CTE para identificar los duplicados
    WITH Duplicados AS (
        SELECT 
            ID,
            NOMBRE,
            EMAIL,
            FECHA_REGISTRO,
            ROW_NUMBER() OVER (PARTITION BY EMAIL ORDER BY FECHA_REGISTRO DESC) AS rn
        FROM dbo.CLIENTES
    )
    DELETE FROM Duplicados
    WHERE rn > 1;  -- Eliminamos todas las filas excepto la más reciente

    COMMIT TRAN;
    PRINT 'Transacción completada correctamente. Duplicados eliminados.';

END TRY
BEGIN CATCH
    ROLLBACK TRAN;
    PRINT 'Error detectado. Transacción revertida.';
END CATCH;



