-- Step 1: Create the TimeDimension Table
IF OBJECT_ID('dbo.TimeDimension', 'U') IS NOT NULL
    DROP TABLE dbo.TimeDimension;

CREATE TABLE dbo.TimeDimension (
    Date DATE PRIMARY KEY,
    DayNumber INT,
    DaySuffix VARCHAR(10),
    DayName VARCHAR(20),
    DayNameShort VARCHAR(10),
    DayOfWeek INT,
    DayOfYear INT,
    WeekOfYear INT,
    MonthNumber INT,
    MonthName VARCHAR(20),
    QuarterNumber INT,
    YearNumber INT,
    FiscalMonth INT,
    FiscalQuarter INT,
    FiscalYear INT,
    FiscalYearPeriod VARCHAR(10)
);

-- Step 2: Create Stored Procedure to Populate for a Year
IF OBJECT_ID('dbo.PopulateTimeDimensionForYear', 'P') IS NOT NULL
    DROP PROCEDURE dbo.PopulateTimeDimensionForYear;
GO

CREATE PROCEDURE dbo.PopulateTimeDimensionForYear
    @InputDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(YEAR(@InputDate), 1, 1);
    DECLARE @EndDate DATE = DATEFROMPARTS(YEAR(@InputDate), 12, 31);

    ;WITH DateSeries AS (
        SELECT @StartDate AS TheDate
        UNION ALL
        SELECT DATEADD(DAY, 1, TheDate)
        FROM DateSeries
        WHERE TheDate < @EndDate
    )
    INSERT INTO dbo.TimeDimension (
        Date,
        DayNumber,
        DaySuffix,
        DayName,
        DayNameShort,
        DayOfWeek,
        DayOfYear,
        WeekOfYear,
        MonthNumber,
        MonthName,
        QuarterNumber,
        YearNumber,
        FiscalMonth,
        FiscalQuarter,
        FiscalYear,
        FiscalYearPeriod
    )
    SELECT
        TheDate,
        DATEPART(DAY, TheDate) AS DayNumber,
        CAST(DATEPART(DAY, TheDate) AS VARCHAR) + 
            CASE 
                WHEN DATEPART(DAY, TheDate) IN (11,12,13) THEN 'th'
                WHEN RIGHT(DATEPART(DAY, TheDate),1) = 1 THEN 'st'
                WHEN RIGHT(DATEPART(DAY, TheDate),1) = 2 THEN 'nd'
                WHEN RIGHT(DATEPART(DAY, TheDate),1) = 3 THEN 'rd'
                ELSE 'th'
            END AS DaySuffix,
        DATENAME(WEEKDAY, TheDate) AS DayName,
        LEFT(DATENAME(WEEKDAY, TheDate), 3) AS DayNameShort,
        DATEPART(WEEKDAY, TheDate) AS DayOfWeek,
        DATEPART(DAYOFYEAR, TheDate) AS DayOfYear,
        DATEPART(WEEK, TheDate) AS WeekOfYear,
        DATEPART(MONTH, TheDate) AS MonthNumber,
        DATENAME(MONTH, TheDate) AS MonthName,
        DATEPART(QUARTER, TheDate) AS QuarterNumber,
        DATEPART(YEAR, TheDate) AS YearNumber,
        -- Assuming Fiscal = Calendar (you can adjust this logic)
        DATEPART(MONTH, TheDate) AS FiscalMonth,
        DATEPART(QUARTER, TheDate) AS FiscalQuarter,
        DATEPART(YEAR, TheDate) AS FiscalYear,
        CAST(DATEPART(YEAR, TheDate) AS VARCHAR) + RIGHT('0' + CAST(DATEPART(MONTH, TheDate) AS VARCHAR), 2) AS FiscalYearPeriod
    FROM DateSeries
    OPTION (MAXRECURSION 366);
END
GO

-- Step 3: Run the stored procedure (for example, for the year 2020)
EXEC dbo.PopulateTimeDimensionForYear '2020-07-14';
SELECT * FROM dbo.TimeDimension ORDER BY Date;

