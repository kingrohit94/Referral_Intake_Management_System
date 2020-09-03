GO
DROP DATABASE IF EXISTS [RIMS];

GO
CREATE DATABASE [RIMS];

GO
USE [RIMS];

/*
	CREATING RELATIONAL DATABASE TABLES
*/

GO
CREATE TABLE [dbo].[Referral_Intake_TestHealthData]
(
    [ClientID] [nvarchar](max) NULL,
    [CreatedDateTime] datetime2 NULL,
    [FYear_Name] [nvarchar](max) NULL,
    [Work_OutsideDay] [nvarchar](max) NULL,
    [StatNew] [nvarchar](max) NULL,
    [TimeTo_NewStat] [nvarchar](max) NULL,
    [FirstStatChange] [nvarchar](max) NULL,
    [TimeTo_FirstStatChange] [nvarchar](max) NULL,
    [TimeTo_PSA_Review] [nvarchar](max) NULL,
    [TimeTo_PSA_Accepted] [nvarchar](max) NULL,
    [TimeTo_Triaged] [nvarchar](max) NULL,
    [TimeTo_CC_Accepted] [nvarchar](max) NULL,
    [TimeTo_Awaiting_CallBack] [nvarchar](max) NULL,
    [StatCompleted] [nvarchar](max) NULL,
    [CompletedDateTime] datetime2 NULL,
    [TimeTo_Completed] [nvarchar](max) NULL,
    [Patient] [nvarchar](max) NULL,
    [Priority] [nvarchar](max) NULL,
    [Referral_Category] [nvarchar](max) NULL,
    [Location] [nvarchar](max) NULL,
    [Completed_UserID] [nvarchar](max) NULL,
    [User_Group_Name] [nvarchar](max) NULL,
    [Completed_Work_OutsideDay] [nvarchar](max) NULL,
    [_1stStat_To_Triage_Hour] [nvarchar](max) NULL,
    [_1stStat_To_Completed_Hour] [nvarchar](max) NULL,
    [TimeTo_Completed_Day] [nvarchar](max) NULL,
    [LastStatChange] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
CREATE SEQUENCE Seq_Nurse
START WITH 100
INCREMENT BY 1;

GO
CREATE TABLE Nurse
(
	NurseID INT DEFAULT NEXT VALUE FOR Seq_Nurse NOT NULL,
	NurseUserName nvarchar(20) NOT NULL,
	NurseGroupName NVARCHAR(50) NOT NULL,

	CONSTRAINT PK_NurseID PRIMARY KEY (NurseID)
);

GO
CREATE SEQUENCE Seq_Department
START WITH 100
INCREMENT BY 1;

GO
CREATE TABLE Department
(
	DepartmentID INT NOT NULL DEFAULT NEXT VALUE FOR Seq_Department,
	DepartmentName NVARCHAR(50) NOT NULL,
	CONSTRAINT PK_DepartmentID PRIMARY KEY (DepartmentID),
	CONSTRAINT U_DepartmentName UNIQUE(DepartmentName)
);

GO
CREATE SEQUENCE Seq_Location
START WITH 100
INCREMENT BY 1;

GO
CREATE TABLE Locations
(
	LocationID INT NOT NULL DEFAULT NEXT VALUE FOR Seq_Location,
	LocationName NVARCHAR(10) NOT NULL
	CONSTRAINT PK_LocationID PRIMARY KEY (LocationID),
	CONSTRAINT U_DepartmentLocation UNIQUE(LocationName)
);

GO
CREATE SEQUENCE Seq_DepartmentLocation
START WITH 100
INCREMENT BY 1;

GO
CREATE TABLE DepartmentLocation
(
	DepartmentLocationID INT DEFAULT NEXT VALUE FOR Seq_DepartmentLocation,
	DepartmentID INT NOT NULL,
	LocationID INT NOT NULL,
	CONSTRAINT PK_DepartmentLocationID PRIMARY KEY (DepartmentLocationID),
	CONSTRAINT FK_DepartmentLocation_DepartmentID FOREIGN KEY (DepartmentID) REFERENCES dbo.Department ( DepartmentID ),
	CONSTRAINT FK_DepartmentLocation_LocationID FOREIGN KEY (LocationID) REFERENCES dbo.Locations ( LocationID )
);

GO
CREATE SEQUENCE Seq_PatientStatus
START WITH 10
INCREMENT BY 1;

GO
CREATE TABLE PatientStatus
(
	StatusID INT NOT NULL DEFAULT NEXT VALUE FOR Seq_PatientStatus,
	StatusName NVARCHAR(40) NOT NULL,
	CONSTRAINT PK_PatientStatus PRIMARY KEY ( StatusID )
);

GO
CREATE SEQUENCE Seq_PriorityType
START WITH 100
INCREMENT BY 1;

GO
CREATE TABLE PriorityType
(
	PriorityTypeID INT NOT NULL DEFAULT NEXT VALUE FOR Seq_PriorityType,
	PriorityTypeName NVARCHAR(30) NOT NULL,
	CONSTRAINT PK_Priority_TypeID PRIMARY KEY ( PriorityTypeID ),
	CONSTRAINT U_Priority_Type_Name UNIQUE( PriorityTypeName )
);

GO
CREATE SEQUENCE Seq_PatientType
START WITH 1000
INCREMENT BY 1;

GO
CREATE TABLE PatientType
(
	PatientTypeID INT NOT NULL DEFAULT NEXT VALUE FOR Seq_PatientType,
	PatientType NVARCHAR(20) NOT NULL,
	CONSTRAINT PK_PatientTypeID PRIMARY KEY (PatientTypeID),
	CONSTRAINT U_PatientType UNIQUE(PatientType)
);

GO
--select * from DepartmentLocation;
CREATE TABLE Patient
(
	PatientID BIGINT PRIMARY KEY NOT NULL,
	PatientTypeID INT NOT NULL,
	PatientReferralCategoryID INT NOT NULL,
	LocationID INT NOT NULL,
	PriorityTypeID INT NOT NULL,
	PatientCurrentStatusID INT NOT NULL,
	CreatedAtWorkingHours NVARCHAR(20) NOT NULL,
	CreatedAtDateTime DATE DEFAULT GETDATE(),
	CreatedAtFY_Name NVARCHAR(10),
	DischargedWorkingHours NVARCHAR(20) NOT NULL, 
	CONSTRAINT FK_Patient_PatientTypeID FOREIGN KEY (PatientTypeID) REFERENCES dbo.PatientType ( PatientTypeID ),
	CONSTRAINT FK_Patient_DepartmentID FOREIGN KEY (PatientReferralCategoryID) REFERENCES dbo.Department ( DepartmentID ),
	CONSTRAINT FK_Patient_LocationID FOREIGN KEY (LocationID) REFERENCES dbo.Locations ( LocationID ),
	CONSTRAINT FK_Patient_PriorityTypeID  FOREIGN KEY (PriorityTypeID) REFERENCES dbo.PriorityType ( PriorityTypeID ),
	CONSTRAINT FK_Patient_PatientCurrentStatusID FOREIGN KEY (PatientCurrentStatusID) REFERENCES dbo.PatientStatus ( StatusID )
);

GO
CREATE SEQUENCE Seq_Patient_PatientStatus
START WITH 100
INCREMENT BY 1;

GO
CREATE TABLE Patient_PatientStatus
(
	Patient_PatientStatusID INT NOT NULL DEFAULT NEXT VALUE FOR Seq_Patient_PatientStatus, 
	PatientID BIGINT NOT NULL,
	StatusID INT NOT NULL,
	Time_To_Status INT,
	MarkedCompletedByNurse INT,
	MarkedCompletedOnDate DATE,
	MarkedCompletedOnTime TIME,
	CONSTRAINT PK_Patient_PatientStatusID PRIMARY KEY (Patient_PatientStatusID),
	CONSTRAINT FK_Patient_PatientStatus_PatientID FOREIGN KEY (PatientID) REFERENCES dbo.Patient ( PatientID ),
	CONSTRAINT FK_Patient_PatientStatus_Patient_StatusID FOREIGN KEY (StatusID) REFERENCES dbo.PatientStatus ( StatusID ),
	CONSTRAINT FK_Patient_PatientStatus_MarkedCompletedByNurse FOREIGN KEY (MarkedCompletedByNurse) REFERENCES dbo.Nurse ( NurseID )
);

--GO
--ALTER TABLE Patient_PatientStatus ADD CONSTRAINT FK_Patient_PatientStatus_PatientID FOREIGN KEY (PatientID) REFERENCES dbo.Patient ( PatientID );

/*
	RESETTING SEQUENCES BEFORE INSERTING DATA INTO RELATIONAL DATABASE
*/

GO
ALTER SEQUENCE [dbo].[Seq_DepartmentLocation] RESTART WITH 100;
GO
ALTER SEQUENCE [dbo].[Seq_Department] RESTART WITH 100;
GO
ALTER SEQUENCE [dbo].[Seq_PatientStatus] RESTART WITH 10;
GO
ALTER SEQUENCE [dbo].[Seq_PriorityType] RESTART WITH 100;
GO
ALTER SEQUENCE [dbo].[Seq_PatientType] RESTART WITH 1000;
GO
ALTER SEQUENCE [dbo].[Seq_Patient_PatientStatus] RESTART WITH 100;
GO
ALTER SEQUENCE [dbo].[Seq_Location] RESTART WITH 100;
GO
ALTER SEQUENCE [dbo].[Seq_Nurse] RESTART WITH 100;

/*
	CREATING PROCEDURES FOR POPULATING THE DATA IN RELATIONAL DATABASE
*/

GO
CREATE PROCEDURE Populate_Nurse_table
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @RowCt INT; 
	
	INSERT INTO Nurse (NurseUserName,NurseGroupName)
	(SELECT Completed_UserID,User_Group_Name FROM Referral_Intake_TestHealthData 
	GROUP BY Completed_UserID,User_Group_Name);

	SET @RowCt = @@ROWCOUNT;
        IF @RowCt = 0
        BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
        END;
    COMMIT TRANSACTION;
END;

GO
CREATE PROCEDURE Populate_Dept_table
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @RowCt INT; 
	
	INSERT INTO Department(DepartmentName)
	(SELECT DISTINCT(Referral_Category) FROM Referral_Intake_TestHealthData);

	SET @RowCt = @@ROWCOUNT;
        IF @RowCt = 0
        BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
        END;
    COMMIT TRANSACTION;
END;

GO
CREATE PROCEDURE Populate_PatientStatus_table
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;
	
    DECLARE @RowCt INT;
		INSERT INTO PatientStatus (StatusName)
	(SELECT DISTINCT (FirstStatChange) FROM Referral_Intake_TestHealthData);

	INSERT INTO PatientStatus (StatusName)
	VALUES ('New');

	SET @RowCt = @@ROWCOUNT;
        IF @RowCt = 0
        BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
        END;
    COMMIT TRANSACTION;
END;

GO
CREATE PROCEDURE Populate_PriorityType_table
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @RowCt INT; 
	
	INSERT INTO PriorityType(PriorityTypeName)
	(SELECT DISTINCT (Priority) FROM Referral_Intake_TestHealthData);

	SET @RowCt = @@ROWCOUNT;
        IF @RowCt = 0
        BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
        END;
    COMMIT TRANSACTION;
END;

GO
CREATE PROCEDURE Populate_PatientType_table
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @RowCt INT; 
	
	INSERT INTO PatientType(PatientType)
	VALUES ('NEW');
	INSERT INTO PatientType(PatientType)
	VALUES ('EXISTING');
	INSERT INTO PatientType(PatientType)
	VALUES ('ACTIVE');

	SET @RowCt = @@ROWCOUNT;
        IF @RowCt = 0
        BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
        END;
    COMMIT TRANSACTION;
END;

GO

CREATE PROCEDURE PreProcessFlatFile
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @RowCt INT
	UPDATE Referral_Intake_TestHealthData set Referral_Category = 'OTHER'
	WHERE Referral_Category IS NULL;
	WITH Referral_Intake_CTE AS (
		SELECT *, ROW_NUMBER() OVER (PARTITION BY ClientID ORDER BY ClientID) row_number
		 FROM 
			dbo.Referral_Intake_TestHealthData
	)
	DELETE FROM Referral_Intake_CTE
	WHERE row_number > 1;

	SET @RowCt = @@ROWCOUNT;
        IF @RowCt = 0
        BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
        END;
    COMMIT TRANSACTION;
END;

GO
CREATE PROCEDURE Populate_Patient_table
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @RowCt INT;
	
	INSERT INTO Patient (PatientID,PatientTypeID,PatientReferralCategoryID,LocationID,PriorityTypeID,PatientCurrentStatusID,
	CreatedAtWorkingHours,CreatedAtDateTime,CreatedAtFY_Name,DischargedWorkingHours)
	(
		SELECT stg.ClientID,p_type.PatientTypeID,dept.DepartmentID,loc.LocationID,priority_type.PriorityTypeID,
		p_status.StatusID,Work_OutsideDay,CreatedDateTime,stg.FYear_Name,Completed_Work_OutsideDay
		FROM Referral_Intake_TestHealthData stg
		JOIN PatientType p_type
		ON stg.Patient = p_type.PatientType
		JOIN Department dept
		ON dept.DepartmentName = stg.Referral_Category
		JOIN Locations loc ON loc.LocationName = stg.Location
		JOIN PriorityType priority_type
		ON priority_type.PriorityTypeName = stg.Priority
		JOIN PatientStatus p_status
		ON p_status.StatusName = stg.LastStatChange
	)

	SET @RowCt = @@ROWCOUNT;
        IF @RowCt = 0
        BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
        END;
    COMMIT TRANSACTION;
END;

GO
CREATE PROCEDURE Populate_Locations
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @RowCt INT; 
	
	INSERT INTO Locations (LocationName)
	(SELECT DISTINCT Location FROM Referral_Intake_TestHealthData);

	SET @RowCt = @@ROWCOUNT;
        IF @RowCt = 0
        BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
        END;
    COMMIT TRANSACTION;
END;

GO
CREATE PROCEDURE Populate_DepartmentLocation
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @RowCt INT; 
	
	INSERT INTO DepartmentLocation (DepartmentID,LocationID)
	(
		SELECT dep.DepartmentID,loc.LocationID FROM Referral_Intake_TestHealthData stg
		INNER JOIN Department dep
		ON dep.DepartmentName = stg.Referral_Category
		INNER JOIN Locations loc
		ON loc.LocationName = stg.Location
	);

	SET @RowCt = @@ROWCOUNT;
        IF @RowCt = 0
        BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
        END;
    COMMIT TRANSACTION;
END;

GO
CREATE PROCEDURE Populate_Patient_PatientStatus_1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @RowCt INT; 
	
	WITH Patient_PatientStatus_CTE AS
	(
		SELECT stg.ClientID AS ClientID,StatNew,ps_new.StatusID [NewStatusID],
		TimeTo_NewStat as TimeTo_NewStat,FirstStatChange as FirstStatChange
		,ps_psa_review.StatusID [FirstStatChangeStatusID],
		TimeTo_FirstStatChange as TimeTo_FirstStatChange
		FROM Referral_Intake_TestHealthData stg
		LEFT JOIN PatientStatus ps_new
		ON ps_new.StatusName = stg.StatNew
		LEFT JOIN PatientStatus ps_psa_review
		ON ps_psa_review.StatusName = stg.FirstStatChange
	)
	SELECT IDENTITY(INT,1,1) AS Temp_ID,* INTO Patient_Temp
	FROM (SELECT * FROM Patient_PatientStatus_CTE) as temp;

	Declare @RowNum INT,@TempID INT,@PatientID INT, @NewStat NVARCHAR(20),@NewStatID INT,@TimeToNewStat INT,
	@FirstStatChange NVARCHAR(20),@FirstStatChangeID INT,@TimeToFirstStatChange INT;

	select @TempID=MAX(Temp_ID) FROM Patient_Temp
	Select @RowNum = Count(*) From Patient_Temp      
	WHILE @RowNum > 0
	BEGIN
		SELECT @PatientID = ClientID,@FirstStatChange = FirstStatChange, @FirstStatChangeID = FirstStatChangeStatusID,
		@TimeToFirstStatChange = TimeTo_FirstStatChange,@NewStatID = NewStatusID,@TimeToNewStat = TimeTo_NewStat
		FROM Patient_Temp where Temp_ID = @TempID
		group by ClientID,FirstStatChange,FirstStatChangeStatusID,TimeTo_FirstStatChange,NewStatusID,
		TimeTo_NewStat;
				
		INSERT INTO Patient_PatientStatus (PatientID,StatusID,Time_To_Status) 
		VALUES (@PatientID,@NewStatID,@TimeToNewStat);
		
		INSERT INTO Patient_PatientStatus (PatientID,StatusID,Time_To_Status) 
		VALUES (@PatientID,@FirstStatChangeID,@TimeToFirstStatChange);

		select top 1 @TempID=Temp_ID from Patient_Temp where Temp_ID < @TempID order by Temp_ID DESC
		set @RowNum = @RowNum - 1
	END
	
	--DELETE TEMP TABLE
	DROP TABLE Patient_Temp;
	
	SET @RowCt = @@ROWCOUNT;
	IF @RowCt = 0
	BEGIN;
		THROW 50001, 'No records found. Check with source system.', 1;
	END;
COMMIT TRANSACTION;
END;

/*
	INSERTING OTHER STATUSES FOR PATIENTS;
*/

GO
CREATE PROCEDURE Populate_Patient_PatientStatus_2
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @RowCt INT; 
	
	Declare @RowNum INT,@PatientID INT, @TimeTo_PSA_Review INT,@PSAReviewID INT = 22,@TimeTo_PSA_Accepted INT,
	@PSA_AcceptedID INT= 15,@TimeTo_Triaged INT, @TriagedID INT = 19,@TimeTo_CC_Accepted INT,@CC_AcceptedID INT = 17,
	@TimeTo_Awaiting_CallBack INT,@Awaiting_CallBackID INT = 21,@TimeTo_Completed INT,@CompletedID INT = 18,
	@CompletedDate DATE,@CompletedTime TIME,@NurseID INT;

	select @PatientID=MAX(ClientID) FROM Referral_Intake_TestHealthData
	Select @RowNum = Count(*) From Referral_Intake_TestHealthData      
	WHILE @RowNum > 0
	BEGIN
		SELECT @PatientID = ClientID,@TimeTo_PSA_Review = TimeTo_PSA_Review,
		@TimeTo_PSA_Accepted = TimeTo_PSA_Accepted,
		@TimeTo_Triaged = TimeTo_Triaged,@TimeTo_CC_Accepted = 
		TimeTo_CC_Accepted,@TimeTo_Awaiting_CallBack = TimeTo_Awaiting_CallBack,
		@TimeTo_Completed = TimeTo_Completed,@CompletedDate = cast(CompletedDateTime as date),@CompletedTime = FORMAT(CompletedDateTime ,'hh:mm:00'),
		@NurseID = (SELECT NurseID FROM Nurse where NurseUserName=Completed_UserID)
		FROM Referral_Intake_TestHealthData where ClientID = @PatientID;
	
		INSERT INTO Patient_PatientStatus (PatientID,StatusID,Time_To_Status) 
		VALUES (@PatientID,@PSAReviewID,@TimeTo_PSA_Review);
		
		INSERT INTO Patient_PatientStatus (PatientID,StatusID,Time_To_Status) 
		VALUES (@PatientID,@PSA_AcceptedID,@TimeTo_PSA_Accepted);

		INSERT INTO Patient_PatientStatus (PatientID,StatusID,Time_To_Status) 
		VALUES (@PatientID,@TriagedID,@TimeTo_Triaged);

		INSERT INTO Patient_PatientStatus (PatientID,StatusID,Time_To_Status) 
		VALUES (@PatientID,@CC_AcceptedID,@TimeTo_CC_Accepted);

		INSERT INTO Patient_PatientStatus (PatientID,StatusID,Time_To_Status) 
		VALUES (@PatientID,@Awaiting_CallBackID,@TimeTo_Awaiting_CallBack);
		
		INSERT INTO Patient_PatientStatus (PatientID,StatusID,Time_To_Status,MarkedCompletedByNurse,MarkedCompletedOnDate,MarkedCompletedOnTime) 
		VALUES (@PatientID,@CompletedID,@TimeTo_Completed,@NurseID,@CompletedDate,@CompletedTime);

		select top 1 @PatientID=ClientID from Referral_Intake_TestHealthData where ClientID < @PatientID order by ClientID DESC
		set @RowNum = @RowNum - 1
	END
	
	SET @RowCt = @@ROWCOUNT;
	IF @RowCt = 0
	BEGIN;
		THROW 50001, 'No records found. Check with source system.', 1;
	END;
COMMIT TRANSACTION;
END;

GO
CREATE PROCEDURE dbo.Populate_3NF_Tables
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	BEGIN TRY
		BEGIN TRANSACTION

		EXECUTE dbo.Populate_Nurse_table;
		EXECUTE dbo.Populate_Dept_table;
		EXECUTE dbo.Populate_Locations;
		EXECUTE dbo.Populate_DepartmentLocation;
		EXECUTE dbo.Populate_PatientType_table;
		EXECUTE dbo.Populate_PatientStatus_table;
		EXECUTE dbo.Populate_PriorityType_table;
		EXECUTE dbo.Populate_Patient_table;
		EXECUTE dbo.Populate_Patient_PatientStatus_1;
		EXECUTE Populate_Patient_PatientStatus_2;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH;
END;
