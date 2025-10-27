Empresa de Financiamiento "Capital PYME"
caso de uso:
La empresa Capital PYME se dedica a otorgar créditos y préstamos a pequeñas y medianas empresas (PYMES) en Latinoamérica. 
Para gestionar su operación, la empresa mantiene una base de datos central que registra la información de:

Empresas Solicitantes (Datos de la PYME: Nombre, Contacto, País).
Préstamos Aprobados (Monto, Fecha de Aprobación, Plazo).
Pagos (Transacciones realizadas por la PYME).
Scores de Riesgo (Evaluaciones crediticias asignadas a cada PYME).

USE PrestamosPYMES
GO
IF OBJECT_ID('DBO.InteresMensual') IS NOT NULL
    DROP FUNCTION DBO.InteresMensual;
GO

CREATE FUNCTION InteresMensual(@MONTO_PRESTAMO MONEY)
RETURNS MONEY
AS
BEGIN
    DECLARE @INTERES MONEY
    SET @INTERES = @MONTO_PRESTAMO * 0.015
    RETURN(@INTERES)
END
GO

--Determinar una comisión del 2% si el Monto Aprobado es >= $50,000, si no, la comisión es $0.
IF OBJECT_ID('DBO.COMISION_RAPIDA') IS NOT NULL
    DROP FUNCTION DBO.COMISION_RAPIDA;
GO

CREATE FUNCTION COMISION_RAPIDA (@MONTO MONEY)
RETURNS MONEY
AS
BEGIN
    DECLARE @RESULTADO MONEY
    IF @MONTO >= 50000 -- Umbral de $50,000 USD
        BEGIN 
            SET @RESULTADO = @MONTO * 0.02 -- Comisión del 2%
        END
    ELSE
        BEGIN
            SET @RESULTADO = 0 
        END
    RETURN(@RESULTADO)
END
GO

---Listar las PYMES de un país específico, incluyendo su Score de Riesgo.
IF OBJECT_ID('DBO.FN_LISTAR_PYMES_POR_PAIS') IS NOT NULL
    DROP FUNCTION DBO.FN_LISTAR_PYMES_POR_PAIS;
GO

CREATE FUNCTION FN_LISTAR_PYMES_POR_PAIS (@PAIS VARCHAR(160))
RETURNS @PYMES_INFO TABLE (
    EmpresaID INT,
    NombreEmpresa VARCHAR(160), 
    ContactoPrincipal VARCHAR(160), 
    Pais VARCHAR(160),
    ScoreRiesgo DECIMAL(3, 2)
)
AS
BEGIN
    INSERT @PYMES_INFO 
    SELECT 
        E.EmpresaID, 
        E.NombreEmpresa, 
        E.ContactoPrincipal, 
        E.Pais,
        R.ScoreRiesgo
    FROM
        Empresas AS E
    INNER JOIN
        ScoresRiesgo AS R ON E.EmpresaID = R.EmpresaID 
    WHERE 
        E.Pais = @PAIS
    RETURN
END
GO

--- Obtener un listado de préstamos aprobados dentro de un rango de fechas.
IF OBJECT_ID('DBO.FN_PRESTAMOS_POR_PERIODO') IS NOT NULL
    DROP FUNCTION DBO.FN_PRESTAMOS_POR_PERIODO;
GO

CREATE FUNCTION FN_PRESTAMOS_POR_PERIODO (@FECHAINICIAL DATE, @FECHAFINAL DATE)
RETURNS TABLE
AS
RETURN(
    SELECT 
        P.PrestamoID, 
        E.NombreEmpresa, 
        P.FechaAprobacion, 
        P.MontoAprobado,
        P.PlazoMeses
    FROM 
        Prestamos AS P 
    INNER JOIN 
        Empresas AS E ON P.EmpresaID = E.EmpresaID
    WHERE 
        P.FechaAprobacion BETWEEN @FECHAINICIAL AND @FECHAFINAL
)
GO
