The Salud-Total pharmacy records patients, medications, prescriptions, and suppliers.

Requirements:
1.-Obtain the total sales per patient and per medication.
2.-Restrict patients under 18 years of age (i.e., filter out or manage access for minors).
3.-Control that patients from the USA are in a special view.
4.-Create indexes to speed up sales queries.
5.-Query suppliers and patients together for marketing purposes.
USE PHARMATON_BI;
GO
CREATE TABLE Patients
(
    PatientID BIGINT NOT NULL PRIMARY KEY,
    FirstName VARCHAR(150),
    LastName VARCHAR(150),
    BirthDate DATE,
    Country VARCHAR(50) DEFAULT 'Mexico',
    CONSTRAINT CK_Age CHECK (DATEDIFF(YEAR,BirthDate,GETDATE())>=18)
);
GO

CREATE TABLE Medications
(
    MedicationID BIGINT NOT NULL PRIMARY KEY,
    MedicationName VARCHAR(150),
    Category VARCHAR(100),
    UnitPrice DECIMAL(10,2)
);
GO

CREATE TABLE Prescriptions
(
    PrescriptionID BIGINT NOT NULL PRIMARY KEY,
    PatientID BIGINT,
    MedicationID BIGINT,
    Quantity INT,
    PrescriptionDate DATE DEFAULT GETDATE(),
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    FOREIGN KEY (MedicationID) REFERENCES Medications(MedicationID)
);
GO

CREATE TABLE Suppliers
(
    SupplierID BIGINT NOT NULL PRIMARY KEY,
    SupplierName VARCHAR(150),
    Country VARCHAR(50)
);
GO

INSERT INTO Patients VALUES
(1,'Carlos','Garcia','1980-01-01','Mexico'),
(2,'Claudia','Hernandez','1990-05-05','USA'),
(3,'Juan','Lopez','2005-01-01','Mexico');

INSERT INTO Medications VALUES
(1,'Ibuprofeno','Analgesico',50.5),
(2,'Amoxicilina','Antibiotico',120.0);

INSERT INTO Prescriptions VALUES
(1,1,1,10,'2025-10-01'),
(2,2,2,5,'2025-10-05');

INSERT INTO Suppliers VALUES
(1,'Farmaceutica Global','USA'),
(2,'Medix S.A.','Mexico');
GO

CREATE VIEW VIEW_PRESCRIPTIONS
WITH ENCRYPTION, SCHEMABINDING, VIEW_METADATA
AS
SELECT 
    p.PatientID, p.FirstName + ' ' + p.LastName AS PatientName, p.Country,
    pr.PrescriptionID, pr.PrescriptionDate,
    m.MedicationName, m.Category, pr.Quantity, m.UnitPrice,
    (pr.Quantity * m.UnitPrice) AS TotalPrice
FROM dbo.Patients p
INNER JOIN dbo.Prescriptions pr ON p.PatientID = pr.PatientID
INNER JOIN dbo.Medications m ON pr.MedicationID = m.MedicationID;
GO

CREATE VIEW VIEW_USA_PATIENTS
AS
SELECT PatientID, FirstName, LastName, Country
FROM Patients
WHERE Country='USA'
WITH CHECK OPTION;
GO

CREATE VIEW VIEW_COMPANIES
AS
SELECT PatientID AS CompanyID, FirstName + ' ' + LastName AS CompanyName, Country
FROM Patients
UNION ALL
SELECT SupplierID AS CompanyID, SupplierName, Country
FROM Suppliers;
GO

CREATE VIEW VIEW_ALL_ENTITIES
AS
SELECT * FROM VIEW_COMPANIES;
GO

CREATE UNIQUE CLUSTERED INDEX IDX_PRESCRIPTIONS ON VIEW_PRESCRIPTIONS
(PatientID, PrescriptionID, MedicationName);
GO

CREATE NONCLUSTERED INDEX IDX_PATIENTNAME ON VIEW_PRESCRIPTIONS
(PatientName);
GO
SELECT PatientName, SUM(TotalPrice) AS TotalGastado
FROM VIEW_PRESCRIPTIONS
GROUP BY PatientName
ORDER BY TotalGastado DESC;
GO

SELECT MedicationName, SUM(TotalPrice) AS TotalVentas
FROM VIEW_PRESCRIPTIONS
GROUP BY MedicationName
ORDER BY TotalVentas DESC;
GO

SELECT * FROM VIEW_USA_PATIENTS;
GO

SELECT * FROM VIEW_ALL_ENTITIES
ORDER BY Country;
GO
