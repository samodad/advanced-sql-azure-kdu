--1. STANDARDIZE COLUMN NAMES (Rename for Readability)
--DATA_CAS_D01 (Work)
EXEC sp_rename '[dbo].[DATA_CAS_D01 (Work)].Type_of_application', 'Application_Type', 'COLUMN';
EXEC sp_rename '[dbo].[DATA_CAS_D01 (Work)].Category_of_leave', 'Visa_Category', 'COLUMN';
EXEC sp_rename '[dbo].[DATA_CAS_D01 (Work)].Industry', 'Industry_Sector', 'COLUMN';
EXEC sp_rename '[dbo].[DATA_CAS_D01 (Work)].column6', 'Applications', 'COLUMN';

-- DATA_CAS_D02
EXEC sp_rename 'dbo.DATA_CAS_D02.Type_of_application', 'Application_Type', 'COLUMN';
EXEC sp_rename 'dbo.DATA_CAS_D02.Institution_type_group', 'Institution_Group', 'COLUMN';
EXEC sp_rename 'dbo.DATA_CAS_D02.Geographical_region', 'Region', 'COLUMN';

-- DATA_CoS_D02
EXEC sp_rename 'dbo.DATA_CoS_D02.Type_of_application', 'Application_Type', 'COLUMN';
EXEC sp_rename 'dbo.DATA_CoS_D02.Category_of_leave', 'Visa_Category', 'COLUMN';

-- MigrationStudySponsorship
EXEC sp_rename 'dbo.MigrationStudySponsorship.Type_of_Application', 'Application_Type', 'COLUMN';
EXEC sp_rename 'dbo.MigrationStudySponsorship.Institution_type_group', 'Institution_Group', 'COLUMN';
EXEC sp_rename 'dbo.MigrationStudySponsorship.Geographical_region', 'Region', 'COLUMN';

--2. FIX DATA TYPES
--Conversions

ALTER TABLE[dbo].[DATA_CAS_D01 (Work)]
ALTER COLUMN Year SMALLINT;

ALTER TABLE [dbo].[DATA_CAS_D01 (Work)]
ALTER COLUMN Quarter NVARCHAR(20);


-- DATA_CAS_D02
ALTER TABLE dbo.DATA_CAS_D02 ALTER COLUMN Applications INT;

-- MigrationStudySponsorship
ALTER TABLE dbo.MigrationStudySponsorship ALTER COLUMN Applications INT;


--3. HANDLE MISSING VALUES
--Replace NULL with “Unknown”

UPDATE dbo.DATA_CAS_D02
SET Applications = 0
WHERE Applications IS NULL;

UPDATE MigrationStudySponsorship
SET Applications = 0
WHERE Applications IS NULL;

--4. REMOVE DUPLICATES
--Find duplicates:
SELECT Year, Quarter, Application_Type, COUNT(*) AS DupCount
FROM [dbo].[DATA_CAS_D01 (Work)]
GROUP BY Year, Quarter, Application_Type
HAVING COUNT(*) > 1;

--Remove duplicates using CTE
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Year, Quarter, Application_Type ORDER BY (SELECT NULL)) AS rn
    FROM [dbo].[DATA_CAS_D01 (Work)]
)
DELETE FROM cte WHERE rn > 1;

WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Year, Quarter, Application_Type, Nationality ORDER BY (SELECT NULL)) AS rn
    FROM DATA_CAS_D02
)
DELETE FROM cte WHERE rn > 1;

WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Year, Quarter, Application_Type, Nationality ORDER BY (SELECT NULL)) AS rn
    FROM dbo.DATA_CoS_D02
)
DELETE FROM cte WHERE rn > 1;

--EXPLORATORY DATA ANALYSIS (EDA)
--Row count
SELECT COUNT(*) AS TotalRows FROM [dbo].[DATA_CAS_D01 (Work)];

--Missing values
SELECT 
    SUM(CASE WHEN Nationality IS NULL THEN 1 END) AS MissingNationality,
    SUM(CASE WHEN Applications IS NULL THEN 1 END) AS MissingApplications
FROM dbo.DATA_CAS_D02;

--Trend over years
SELECT Year, SUM(Applications) AS Total
FROM dbo.MigrationStudySponsorship
GROUP BY Year
ORDER BY Year;

--AGGREGATIONS

--Applications by Region
SELECT Region, SUM(Applications) AS Total
FROM dbo.DATA_CAS_D02
GROUP BY Region
ORDER BY Total DESC;

-- RANKING FUNCTIONS
--Rank Top Nationalities
SELECT Nationality, SUM(Applications) AS TotalApps,
       RANK() OVER (ORDER BY SUM(Applications) DESC) AS RankOrder
FROM dbo.MigrationStudySponsorship
GROUP BY Nationality;

--CREATE VIEWS
--View: Nationality Trend
CREATE VIEW vw_NationalityTrend AS
SELECT Year, Nationality, SUM(Applications) AS Total
FROM dbo.DATA_CAS_D02
GROUP BY Year, Nationality;

--STORED PROCEDURES
--Procedure: Get Applications by Year
CREATE PROCEDURE sp_GetApplicationsByYear
    @Year SMALLINT
AS
BEGIN
    SELECT *
    FROM [dbo].[DATA_CAS_D01 (Work)]
    WHERE Year = @Year;
END;


--Procedure: Top N Nationalities
CREATE PROCEDURE sp_TopNationalities
    @TopN INT
AS
BEGIN
    SELECT TOP (@TopN) Nationality, SUM(Applications) AS Total
    FROM dbo.MigrationStudySponsorship
    GROUP BY Nationality
    ORDER BY Total DESC;
END;









