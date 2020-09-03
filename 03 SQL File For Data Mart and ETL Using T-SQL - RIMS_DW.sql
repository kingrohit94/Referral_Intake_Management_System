GO
DROP DATABASE IF EXISTS [RIMS_DW];

GO
CREATE DATABASE [RIMS_DW];

GO
USE [RIMS_DW];

/*
	CREATING DIMENSION TABLES
*/

GO
CREATE TABLE dbo.DimDate
(
	DateKey INT NOT NULL,
	DateValue DATE NOT NULL,
	Year SMALLINT NOT NULL,
	Month TINYINT NOT NULL,
	Day TINYINT NOT NULL,
	Quarter TINYINT NOT NULL,
	StartOfMonth DATE NOT NULL,
	EndOfMonth DATE NOT NULL,
	MonthName VARCHAR(9) NOT NULL,
	DayOfWeekName VARCHAR(9) NOT NULL,
	CONSTRAINT PK_DimDate PRIMARY KEY (DateKey)
);

GO
CREATE TABLE dbo.DimTime
(
    TimeKey INT NOT NULL,
    TimeValue TIME(0) NULL,
    Hour INT NULL,
    Minute INT NULL,
    AMPM VARCHAR(2) NOT NULL,
    HourFromTo12 VARCHAR(17) NULL,
    HourFromTo24 VARCHAR(13) NULL
);

GO
CREATE TABLE dbo.DimPatient
(
	PatientKey INT NOT NULL,
	PatientUsername  BIGINT ,
	PatientType NVARCHAR(20) NOT NULL,
	PriorityTypeName  NVARCHAR(30) NOT NULL,
	CreatedAtDateTime DATE DEFAULT GETDATE(), 
	CreatedAtWorkingHours NVARCHAR(20) NOT NULL,
	CreatedAtFY_Name NVARCHAR(10),
	PatientStatusName NVARCHAR(40),
	DepartmentName NVARCHAR(50),
	LocationName NVARCHAR(20),
	Time_To_Status int,
	MarkedCompletedOnDate date,
	MarkedCompletedOnTime time,
	NurseUserName NVARCHAR(20),
	DischargedWorkingHours NVARCHAR(20) NOT NULL, 
	StartDate DATE DEFAULT GETDATE() NOT NULL,
	EndDate DATE NULL,
	CONSTRAINT PK_DimPatient PRIMARY KEY CLUSTERED (PatientKey)
);

GO
CREATE TABLE dbo.DimDepartment
(
	DeptKey INT NOT NULL,
	DepartmentName NVARCHAR(50),
	LocationName NVARCHAR(40),
	CONSTRAINT PK_DimDepartment PRIMARY KEY CLUSTERED (DeptKey)
);

GO
CREATE TABLE dbo.DimNurse
(
	NurseKey INT,
	NurseUserName nvarchar(20) NOT NULL,
	NurseGroupName NVARCHAR(50) NOT NULL,
	StartDate DATE,
	EndDate DATE,
	CONSTRAINT PK_DimNurse PRIMARY KEY CLUSTERED (NurseKey)
);

/*
	CREATING STORED PROCEDURE TO POPULATE dbo.DimDate TABLE
*/

GO
CREATE PROCEDURE dbo.DimDate_Load
@DateValue DATE, --The data insertion will start from this date
@NumOfYears INT  --The data will be inserted for this number of years
AS
BEGIN
	DECLARE @YearLimit DATE
	SET @YearLimit = (SELECT DATEADD(YEAR, @NumOfYears, @DateValue))

	WHILE (@DateValue < @YearLimit)
	BEGIN
		INSERT INTO dbo.DimDate
		SELECT CAST(YEAR(@DateValue) * 10000 + MONTH(@DateValue) * 100 + DAY(@DateValue) AS INT),
			   @DateValue,
			   YEAR(@DateValue),
			   MONTH(@DateValue),
			   DAY(@DateValue),
			   DATEPART(qq, @DateValue),
			   DATEADD(DAY, 1, EOMONTH(@DateValue, -1)),
			   EOMONTH(@DateValue),
			   DATENAME(mm, @DateValue),
			   DATENAME(dw, @DateValue);

		SET @DateValue = (SELECT DATEADD(DAY, 1, @DateValue))
	END
END;

/*
	POPULATING dbo.DimDate TABLE
*/

GO
EXEC dbo.DimDate_Load '2012-01-01', 10 --inserting values starting from 1st Jan, 2012 upto 10 years

/*
	CREATING STAGE TABLES FOR EXTRACTION
*/

GO
CREATE TABLE dbo.Patient_Stage
(
	PatientUsername NVARCHAR(MAX),
	PatientType NVARCHAR(MAX),
	PriorityTypeName NVARCHAR(MAX),
	CreatedAtDateTime NVARCHAR(MAX),
	CreatedAtWorkingHours NVARCHAR(MAX),
	CreatedAtFY_Name NVARCHAR(MAX),
	PatientStatusName NVARCHAR(MAX),
	DepartmentName NVARCHAR(MAX),
	LocationName NVARCHAR(MAX),
	Time_To_Status NVARCHAR(MAX),
	MarkedCompletedOnDate NVARCHAR(MAX),
	MarkedCompletedOnTime NVARCHAR(MAX),
	DischargedWorkingHours NVARCHAR(MAX),
	NurseID NVARCHAR(MAX),
	StartDate DATE,
	EndDate DATE
);

GO
CREATE TABLE dbo.Department_Stage
(
	DepartmentName NVARCHAR(50),
	LocationName NVARCHAR(40)
)

/*
	CREATING EXTRACTS
*/

/*
Creating dbo.Patients_Extract to load dbo.Patient_Stage table
*/
GO
CREATE PROCEDURE dbo.Patients_Extract
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	DECLARE @RowCt INT;
	
	TRUNCATE TABLE dbo.Patient_Stage;

	WITH PatientDetails AS (SELECT P.PatientID,
								   PAT.PatientType,
								   PRT.PriorityTypeName,
								   PAS.StatusName,
								   PPS.Time_To_Status,
								   PPS.MarkedCompletedOnDate,
								   PPS.MarkedCompletedOnTime
							FROM RIMS.dbo.Patient P
							LEFT JOIN RIMS.dbo.PatientType PAT ON PAT.PatientTypeID = P.PatientTypeID
							LEFT JOIN RIMS.dbo.PriorityType PRT ON PRT.PriorityTypeID = P.PriorityTypeID
							LEFT JOIN RIMS.dbo.Patient_PatientStatus PPS ON PPS.PatientID = P.PatientID
							LEFT JOIN RIMS.dbo.PatientStatus PAS ON PAS.StatusID = PPS.StatusID)
	
	INSERT INTO dbo.Patient_Stage
	(
		PatientUsername,
		PatientType,
		PriorityTypeName,
		CreatedAtDateTime,
		CreatedAtWorkingHours,
		CreatedAtFY_Name,
		PatientStatusName,
		DepartmentName,
		LocationName,
		Time_To_Status,
		MarkedCompletedOnDate,
		MarkedCompletedOnTime,
		DischargedWorkingHours,
		NurseID
	)
	
	SELECT P.PatientID,
		   PD.PatientType,
		   PD.PriorityTypeName,
		   P.CreatedAtDateTime,
		   P.CreatedAtWorkingHours,
		   P.CreatedAtFY_Name,
		   PD.StatusName,
		   D.DepartmentName,
		   L.LocationName,
		   PD.Time_To_Status,
		   ISNULL(PD.MarkedCompletedOnDate,RIT.CompletedDateTime)[MarkedCompletedOnDate],
		   PD.MarkedCompletedOnTime,
		   P.CreatedAtWorkingHours,
		   RIT.Completed_UserID
	FROM RIMS.dbo.Patient P
	INNER JOIN PatientDetails PD ON PD.PatientID = P.PatientID
	INNER JOIN RIMS.dbo.Referral_Intake_TestHealthData RIT ON RIT.ClientID = P.PatientID
	INNER JOIN RIMS.dbo.Department D ON D.DepartmentID = P.PatientReferralCategoryID
	INNER JOIN RIMS.dbo.Locations L ON L.LocationID = P.LocationID

	SET @RowCt = @@ROWCOUNT;

	IF @RowCt = 0
	BEGIN;
		THROW 50001 , 'No records found. Check with source system.', 1;
	END;
END;

/*
	Creating dbo.Departments_Extract to load dbo.Department_Stage table
*/
GO
CREATE PROCEDURE dbo.Departments_Extract
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	DECLARE @RowCt INT;
	
	TRUNCATE TABLE dbo.Department_Stage;

	WITH DepartmentDetails AS (SELECT D.DepartmentName,
									  L.LocationName
							FROM RIMS.dbo.Department D
							LEFT JOIN RIMS.dbo.DepartmentLocation DL ON DL.DepartmentID = D.DepartmentID
							LEFT JOIN RIMS.dbo.Locations L ON L.LocationID = DL.LocationID
							GROUP BY D.DepartmentName,
									  L.LocationName)

	INSERT INTO dbo.Department_Stage
	(
		DepartmentName,
		LocationName
	)
	SELECT DepartmentName,
		   LocationName
	FROM DepartmentDetails

	SET @RowCt = @@ROWCOUNT;

	IF @RowCt = 0
	BEGIN;
		THROW 50001 , 'No records found. Check with source system.', 1;
	END;
END;

/*
	CREATING PRELOAD TABLES FOR TRANSFORMATION
*/

GO
CREATE SEQUENCE dbo.Seq_Patient_Preload START WITH 100
INCREMENT BY 1;

GO
CREATE TABLE dbo.Patient_Preload
(
	PatientKey INT NOT NULL,
	PatientUsername BIGINT NOT NULL,
	PatientType NVARCHAR(20) NOT NULL,
	PriorityTypeName NVARCHAR(30) NOT NULL,
	CreatedAtDateTime DATE,
	CreatedAtWorkingHours NVARCHAR(20) NOT NULL,
	CreatedAtFY_Name NVARCHAR(10),
	PatientStatusName NVARCHAR(40),
	DepartmentName NVARCHAR(50),
	LocationName NVARCHAR(20),
	Time_To_Status INT,
	MarkedCompletedOnDate DATE,
	MarkedCompletedOnTime TIME,
	MarkedCompletedBy NVARCHAR(20),
	DischargedWorkingHours NVARCHAR(20) NOT NULL,
	StartDate DATE,
	EndDate DATE,
	CONSTRAINT PK_Patient_Preload PRIMARY KEY CLUSTERED (PatientKey)
);

GO
CREATE SEQUENCE dbo.Seq_Department_Preload START WITH 100
INCREMENT BY 1;

GO
CREATE TABLE dbo.Department_Preload
(
	DeptKey INT NOT NULL,
	DepartmentName NVARCHAR(50),
	LocationName NVARCHAR(40),
	CONSTRAINT PK_Department_Preload PRIMARY KEY CLUSTERED (DeptKey)
)

GO
CREATE SEQUENCE dbo.Seq_Nurse_Preload START WITH 100
INCREMENT BY 1;

GO
CREATE TABLE dbo.Nurse_Preload
(
	NurseKey INT,
	NurseUserName NVARCHAR(20) NOT NULL,
	NurseGroupName NVARCHAR(50) NOT NULL,
	StartDate DATE,
	EndDate DATE,
	CONSTRAINT PK_Nurse_Preload PRIMARY KEY CLUSTERED (NurseKey)
)

/*
	CREATING TRANSFORMS
*/

/*
	Creating Patients_Transform
*/
GO
CREATE PROCEDURE dbo.Patients_Transform
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @StartDate DATE = GETDATE();
	DECLARE @EndDate DATE = DATEADD(dd,-1,GETDATE());
	
	BEGIN TRY
	BEGIN TRANSACTION
		TRUNCATE TABLE dbo.Patient_Preload;

		--Add updated records
		INSERT INTO dbo.Patient_Preload
		SELECT NEXT VALUE FOR dbo.Seq_Patient_Preload AS PatientKey,
			   stg.PatientUsername,
			   stg.PatientType,
			   stg.PriorityTypeName,
			   stg.CreatedAtDateTime,
			   stg.CreatedAtWorkingHours,
			   stg.CreatedAtFY_Name,
			   stg.PatientStatusName,
			   stg.DepartmentName,
			   stg.LocationName,
			   stg.Time_To_Status,
			   stg.MarkedCompletedOnDate,
			   stg.MarkedCompletedOnTime,
			   stg.NurseID,
			   stg.DischargedWorkingHours,
			   @StartDate,
			   NULL
		FROM dbo.Patient_Stage stg
		JOIN dbo.DimPatient P ON stg.PatientUsername = P.PatientUsername
									AND P.EndDate IS NULL
		WHERE stg.PatientType <> P.PatientType
			  OR stg.PriorityTypeName <> P.PriorityTypeName
			  OR stg.CreatedAtDateTime <> P.CreatedAtDateTime
			  OR stg.CreatedAtWorkingHours <> P.CreatedAtWorkingHours
			  OR stg.PatientStatusName <> P.PatientStatusName
			  OR stg.MarkedCompletedOnDate <> P.MarkedCompletedOnDate
			  OR stg.MarkedCompletedOnTime <> P.MarkedCompletedOnTime
			  OR stg.NurseID <> P.NurseUserName;

		--Add existing records, and expire as necessary
		INSERT INTO dbo.Patient_Preload
		SELECT P.PatientKey,
			   P.PatientUsername,
			   P.PatientType,
			   P.PriorityTypeName,
			   P.CreatedAtDateTime,
			   P.CreatedAtWorkingHours,
			   P.CreatedAtFY_Name,
			   P.PatientStatusName,
			   P.DepartmentName,
			   P.LocationName,
			   P.Time_To_Status,
			   P.MarkedCompletedOnDate,
			   P.MarkedCompletedOnTime,
			   P.NurseUserName,
			   P.DischargedWorkingHours,
			   P.StartDate,
			   CASE
				   WHEN PP.PatientUsername IS NULL
					   THEN NULL
				   ELSE
					   @EndDate
			   END AS EndDate
		FROM dbo.DimPatient P
		LEFT JOIN dbo.Patient_Preload PP ON PP.PatientUsername = P.PatientUsername
											  AND P.EndDate IS NULL;

		--Create new records
		INSERT INTO dbo.Patient_Preload
		SELECT NEXT VALUE FOR dbo.Seq_Patient_Preload AS PatientKey,
			   stg.PatientUsername,
			   stg.PatientType,
			   stg.PriorityTypeName,
			   stg.CreatedAtDateTime,
			   stg.CreatedAtWorkingHours,
			   stg.CreatedAtFY_Name,
			   stg.PatientStatusName,
			   stg.DepartmentName,
			   stg.LocationName,
			   stg.Time_To_Status,
			   stg.MarkedCompletedOnDate,
			   stg.MarkedCompletedOnTime,
			   stg.NurseID,
			   stg.DischargedWorkingHours,
			   @StartDate,
			   NULL
		FROM dbo.Patient_Stage stg
		WHERE NOT EXISTS (SELECT 1 FROM RIMS_DW.dbo.DimPatient DP
						  WHERE stg.PatientUsername = DP.PatientUsername);

		--Expire missing records
		INSERT INTO dbo.Patient_Preload
		SELECT DP.PatientKey,
			   DP.PatientUsername,
			   DP.PatientType,
			   DP.PriorityTypeName,
			   DP.CreatedAtDateTime,
			   DP.CreatedAtWorkingHours,
			   DP.CreatedAtFY_Name,
			   DP.PatientStatusName,
			   DP.DepartmentName,
			   DP.LocationName,
			   DP.Time_To_Status,
			   DP.MarkedCompletedOnDate,
			   DP.MarkedCompletedOnTime,
			   DP.NurseUserName,
			   DP.DischargedWorkingHours,
			   DP.StartDate,
			   @EndDate
		FROM dbo.DimPatient DP
		WHERE NOT EXISTS (SELECT 1 FROM dbo.Patient_Stage stg
						  WHERE stg.PatientUsername = DP.PatientUsername)
			  AND DP.EndDate IS NULL;

	COMMIT TRANSACTION;
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH;
END;

/*
	Creating Nurses_Transform
*/
GO
CREATE PROCEDURE dbo.Nurses_Transform
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @StartDate DATE = GETDATE();
	DECLARE @EndDate DATE = DATEADD(dd,-1,GETDATE());
	
	BEGIN TRY
	BEGIN TRANSACTION
		TRUNCATE TABLE dbo.Nurse_Preload;

		--Add updated records
		INSERT INTO dbo.Nurse_Preload
		SELECT NEXT VALUE FOR dbo.Seq_Nurse_Preload AS NurseKey,
			   N.NurseUserName,
			   N.NurseGroupName,
			   @StartDate,
			   NULL
		FROM dbo.Patient_Stage stg
		LEFT JOIN RIMS.dbo.Nurse N ON N.NurseUserName = stg.NurseID
		JOIN dbo.DimNurse DN ON DN.NurseUserName = N.NurseUserName
									    AND DN.EndDate IS NULL
		WHERE DN.NurseGroupName <> N.NurseGroupName

		--Add existing records, and expire as necessary
		INSERT INTO dbo.Nurse_Preload
		SELECT N.NurseKey,
			   N.NurseUserName,
			   N.NurseGroupName,
			   N.StartDate,
			   @EndDate
		FROM dbo.DimNurse N
		LEFT JOIN dbo.Nurse_Preload NP ON NP.NurseUserName = N.NurseUserName
											  AND N.EndDate IS NULL;

		--Create new records
		INSERT INTO dbo.Nurse_Preload
		SELECT NEXT VALUE FOR dbo.Seq_Nurse_Preload AS NurseKey,
			   N.NurseUserName,
			   N.NurseGroupName,
			   @StartDate,
			   NULL
		FROM dbo.Patient_Stage stg
		LEFT JOIN RIMS.dbo.Nurse N ON N.NurseUserName = stg.NurseID
		WHERE NOT EXISTS (SELECT 1 FROM dbo.DimNurse DN
						  WHERE N.NurseUserName = DN.NurseUserName)
		GROUP BY N.NurseUserName,
			     N.NurseGroupName

	COMMIT TRANSACTION;
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH;
END;

/*
	Creating Departments_Transform
*/
GO
CREATE PROCEDURE dbo.Departments_Transform
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	BEGIN TRY
	BEGIN TRANSACTION
		TRUNCATE TABLE dbo.Department_Preload;

		--Use Sequence to create new surrogate keys (Create new records)
		INSERT INTO dbo.Department_Preload
		SELECT NEXT VALUE FOR dbo.Seq_Department_Preload AS DeptKey,
			   stg.DepartmentName,
			   stg.LocationName
		FROM dbo.Department_Stage stg
		WHERE NOT EXISTS (SELECT 1 FROM dbo.DimDepartment DD
						  WHERE stg.DepartmentName = DD.DepartmentName
								AND stg.LocationName = DD.LocationName);

		--Use existing surrogate key if one exists (Add updated records)
		INSERT INTO dbo.Department_Preload
		SELECT DD.DeptKey,
			   stg.DepartmentName,
			   stg.LocationName
		FROM dbo.Department_Stage stg
		JOIN dbo.DimDepartment DD ON stg.DepartmentName = DD.DepartmentName
									         AND stg.LocationName = DD.LocationName
		GROUP BY DD.DeptKey,
			   stg.DepartmentName,
			   stg.LocationName;
	COMMIT TRANSACTION;
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH;
END;

/*
	CREATING LOADS FOR DIMENSION TABLES
*/

/*
	Creating dbo.Patients_Load
*/
GO
CREATE PROCEDURE dbo.Patients_Load
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	BEGIN TRY
		BEGIN TRANSACTION
		DELETE DP FROM dbo.DimPatient DP
		JOIN dbo.Patient_Preload PP ON PP.PatientKey = DP.PatientKey

		INSERT INTO dbo.DimPatient
		SELECT * FROM dbo.Patient_Preload
	
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH;
END;

/*
	Creating dbo.Nurses_Load
*/
GO
CREATE PROCEDURE dbo.Nurses_Load
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	BEGIN TRY
		BEGIN TRANSACTION
		DELETE DN FROM dbo.DimNurse DN
		JOIN dbo.Nurse_Preload NP ON NP.NurseKey = DN.NurseKey

		INSERT INTO dbo.DimNurse
		SELECT * FROM dbo.Nurse_Preload
	
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH;
END;

/*
	Creating dbo.Departments_Load
*/
GO
CREATE PROCEDURE dbo.Departments_Load
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	BEGIN TRY
		BEGIN TRANSACTION
		DELETE DD FROM dbo.DimDepartment DD
		JOIN dbo.Department_Preload DP ON DP.DeptKey = DD.DeptKey

		INSERT INTO dbo.DimDepartment
		SELECT * FROM dbo.Department_Preload
	
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH;
END;

/*
	CREATING FACT PATIENT TABLE
*/

GO
CREATE TABLE dbo.FactPatient
(
	PatientKey INT NOT NULL,
	DeptKey INT NOT NULL,
	NurseKey INT NOT NULL,
	AdmitDateKey INT NOT NULL,
	DischargeDateKey INT NOT NULL,
	TotalAdmittedDays INT NOT NULL,
	TotalMins DECIMAL(10,2),
	AverageMins DECIMAL(10,2)
	CONSTRAINT FK_DimDate_AdmitDateKey FOREIGN KEY (AdmitDateKey) REFERENCES dbo.DimDate (DateKey),
	CONSTRAINT FK_DimDate_DischargedDateKey FOREIGN KEY (DischargeDateKey) REFERENCES dbo.DimDate (DateKey),
	CONSTRAINT FK_DimDepartment_DeptKey FOREIGN KEY (DeptKey) REFERENCES dbo.DimDepartment (DeptKey),
	CONSTRAINT FK_DimNurse_NurseKey FOREIGN KEY (NurseKey) REFERENCES dbo.DimNurse (NurseKey)
);

GO
CREATE INDEX IX_FactPatient_AdmitDateKey ON dbo.FactPatient(AdmitDateKey);
GO
CREATE INDEX IX_FactPatient_DischargedDateKey ON dbo.FactPatient(DischargeDateKey);
GO
CREATE INDEX IX_FactPatient_DeptKey ON dbo.FactPatient(DeptKey);
GO
CREATE INDEX IX_FactPatient_NurseKey ON dbo.FactPatient(NurseKey);

/*
	CREATING FACT PATIENT STAGE TABLE
*/

/*
GO
CREATE TABLE dbo.FactPatient_Stage
(
	PatientID NVARCHAR(MAX),
	DepartmentName NVARCHAR(MAX),
	AdmitDate NVARCHAR(MAX),
	DischargeDate NVARCHAR(MAX),
	OperatedBy NVARCHAR(MAX),
	FirstStat_To_Triage_Hour NVARCHAR(MAX),
	FirstStat_To_Completed_Hour NVARCHAR(MAX)
);
*/

/*
	CREATING FACT PATIENT EXTRACT TO POPULATE dbo.FactPatient_Stage TABLE
*/

/*
GO
CREATE PROCEDURE dbo.FactPatients_Extract
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	DECLARE @RowCt INT;
	
	TRUNCATE TABLE RIMS_DW.dbo.FactPatient_Stage;

	WITH PatientDetails AS (SELECT P.PatientID,
								   D.DepartmentName,
								   P.CreatedAtDateTime,
								   PPS.MarkedCompletedOnDate,
								   PPS.MarkedCompletedByNurse,
								   RIT._1stStat_To_Triage_Hour,
								   RIT._1stStat_To_Completed_Hour
							FROM RIMS.dbo.Patient P
							LEFT JOIN RIMS.dbo.Referral_Intake_TestHealthData RIT ON RIT.ClientID = P.PatientID
							LEFT JOIN RIMS.dbo.Department D ON D.DepartmentName = RIT.Referral_Category
							LEFT JOIN RIMS.dbo.Patient_PatientStatus PPS ON PPS.PatientID = P.PatientID)

	INSERT INTO RIMS_DW.dbo.FactPatient_Stage
	SELECT PatientID,
		   DepartmentName,
		   CreatedAtDateTime,
		   MarkedCompletedOnDate,
		   MarkedCompletedByNurse,
		   _1stStat_To_Triage_Hour,
		   _1stStat_To_Completed_Hour
	FROM PatientDetails

	SET @RowCt = @@ROWCOUNT;

	IF @RowCt = 0
	BEGIN;
		THROW 50001 , 'No records found. Check with source system.', 1;
	END;
END;
*/

/*
	CREATING FACT PATIENT LOAD TABLE
*/

GO
CREATE TABLE dbo.FactPatient_Preload
(
	PatientKey INT,
	DeptKey INT,
	NurseKey INT,
	AdmitDate NVARCHAR(MAX),
	DischargeDate NVARCHAR(MAX),
	--FirstStat_To_Triage_Hour NVARCHAR(MAX),
	--FirstStat_To_Completed_Hour NVARCHAR(MAX)
	TotalDays NVARCHAR(MAX),
	TotalMins DECIMAL(10,2),
	AverageMins DECIMAL(10,2)
);

/*
	CREATING FACT PATIENT TRANSFORM
*/

GO
CREATE PROCEDURE dbo.FactPatients_Transform
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @StartDate DATE = GETDATE();
	DECLARE @EndDate DATE = DATEADD(dd,-1,GETDATE());
	
	BEGIN TRY
	BEGIN TRANSACTION
		TRUNCATE TABLE RIMS_DW.dbo.FactPatient_Preload;

		INSERT INTO dbo.FactPatient_Preload(PatientKey, DeptKey, NurseKey, AdmitDate, DischargeDate, TotalDays, TotalMins, AverageMins)
		(
			SELECT pat_preload.PatientUsername
				   ,dep_preload.DeptKey
				   ,NurseKey
				   ,CAST(YEAR(pat_preload.CreatedAtDateTime) * 10000 + MONTH(pat_preload.CreatedAtDateTime) * 100 + DAY(pat_preload.CreatedAtDateTime) AS INT) AS AdmitDateKey
				   ,CAST(YEAR(pat_preload.MarkedCompletedOnDate) * 10000 + MONTH(pat_preload.MarkedCompletedOnDate) * 100 + DAY(pat_preload.MarkedCompletedOnDate) AS INT) AS MarkedCompletedDateKey
				   ,DATEDIFF(DAY,pat_preload.CreatedAtDateTime, pat_preload.MarkedCompletedOnDate ) [TOTAL_DAYS_SPENT]
				   ,SUM(pat_preload.Time_To_Status) AS TotalMins
				   ,AVG(pat_preload.Time_To_Status) AS AverageMins
				   --,COUNT(*) AS COUNT
			FROM RIMS.dbo.Patient pat
			JOIN RIMS.dbo.Department dep ON dep.DepartmentID = pat.PatientReferralCategoryID
			INNER JOIN Patient_Preload pat_preload ON pat_preload.PatientUsername = pat.PatientID
			INNER JOIN dbo.Department_Preload dep_preload ON dep_preload.DepartmentName = dep.DepartmentName
															 AND dep_preload.LocationName = pat_preload.LocationName
			INNER JOIN Nurse_Preload nurse_preload ON nurse_preload.NurseUserName = pat_preload.MarkedCompletedBy
			GROUP BY pat_preload.PatientUsername
					 ,dep_preload.DeptKey
					 ,NurseKey
					 ,pat_preload.CreatedAtDateTime
					 ,pat_preload.MarkedCompletedOnDate
		)
		
	COMMIT TRANSACTION;
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH;
END;

/*
	CREATING FACT PATIENT LOAD
*/

GO
CREATE PROCEDURE dbo.FactPatients_Load
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	BEGIN TRY
		BEGIN TRANSACTION

		INSERT INTO FactPatient
		SELECT * FROM FactPatient_Preload;

		COMMIT TRANSACTION;
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH;
END;

/*
	CREATING FACT NURSE TABLE
*/

GO
CREATE TABLE FactNurse
(
	NurseKey INT,
	DeptKey INT,
	LocationName NVARCHAR(20),
	HandledOnDate DATE,
	TotalPatientsHandled INT,
	CONSTRAINT FK_DimNurseFactNurse_NurseKey FOREIGN KEY (NurseKey) REFERENCES dbo.DimNurse (NurseKey),
	CONSTRAINT FK_DimDepartmentFactNurse_DeptKey FOREIGN KEY (DeptKey) REFERENCES dbo.DimDepartment (DeptKey)
)

GO
CREATE INDEX IX_FactNurse_NurseKey ON dbo.FactNurse(NurseKey);
GO
CREATE INDEX IX_FactNurse_DeptKey ON dbo.FactNurse(DeptKey);

/*
	CREATING FACT NURSE LOAD
*/

GO
CREATE PROCEDURE FactNurse_Load
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;

			INSERT INTO dbo.FactNurse(NurseKey, DeptKey, LocationName, HandledOnDate, TotalPatientsHandled)
			
			SELECT NP.NurseKey
				   ,DEP.DeptKey
				   ,PAT.LocationName
				   ,PAT.MarkedCompletedOnDate
				   ,COUNT(PAT.MarkedCompletedOnDate) AS TotalPatientsHandled
			FROM dbo.Patient_Preload PAT
			INNER JOIN dbo.Nurse_Preload NP ON NP.NurseUserName = PAT.MarkedCompletedBy
			INNER JOIN dbo.Department_Preload DEP ON DEP.DepartmentName = PAT.DepartmentName
			GROUP BY NP.NurseKey
					 ,DEP.DeptKey
				     ,PAT.LocationName
					 ,PAT.MarkedCompletedOnDate

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
