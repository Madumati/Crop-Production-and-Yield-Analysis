CREATE DATABASE PROJECT_1;
USE PROJECT_1;
--C:\Users\Windows\Documents\SQL Server Management Studio\project_1.sql--
--CREATING TABLE --
CREATE TABLE CROP_DETAILS(
State_Name VARCHAR(max),

District_Name VARCHAR(max),
Crop_Year VARCHAR(MAX),
Season VARCHAR(max),
Crop VARCHAR(max),
Area VARCHAR(max),
Production VARCHAR(max));

drop table CROP_DETAILS;

SELECT * FROM CROP_DETAILS;


--IMPORTING DATA TO  TABLE--
bulk insert CROP_DETAILS
from 'C:\Users\Windows\Downloads\Crop_prod_study.csv'
with(Fieldterminator=',',rowterminator='\n',firstrow =2);

--DATA VALIDATION--
SELECT COLUMN_NAME, DATA_TYPE

FROM INFORMATION_SCHEMA.COLUMNS

ALTER TABLE CROP_DETAILS
ALTER COLUMN PRODUCTION float;

ALTER TABLE CROP_DETAILS
ALTER COLUMN area float;

ALTER TABLE CROP_DETAILS
ALTER COLUMN crop_year int;

--1.Calculate crop yield (production per unit area) to assess which crops are the most efficient in production.--

SELECT CROP,AREA,PRODUCTION,(PRODUCTION/AREA) AS CROP_YIELD
FROM CROP_DETAILS
WHERE AREA>0
ORDER BY CROP_YIELD DESC;


--2.calculates the year-over-year percentage growth in crop production for each state and crop.--
WITH YearlyProduction AS (
    SELECT 
        State_Name,
        crop,
        crop_year,
        production,
        LAG(production) OVER (PARTITION BY State_Name, crop ORDER BY crop_year) AS previous_year_production
    FROM 
        CROP_DETAILS
),

GrowthCalculation AS (
    SELECT 
        State_Name,
        crop,
        crop_year,
        production,
        previous_year_production,
        CASE 
            WHEN previous_year_production IS NULL THEN NULL  -- No previous year data
			WHEN previous_year_production = 0 THEN NULL
            ELSE ((production - previous_year_production) / previous_year_production) * 100
        END AS percentage_growth
    FROM 
        YearlyProduction
)

SELECT 
    state_name,
    crop,
    crop_year,
    production,
    previous_year_production,
    percentage_growth
FROM 
    GrowthCalculation
ORDER BY 
    State_name, crop,crop_year;



--3.calculates each state's average yield (production per area) and identifies the top N states with the highest average yield over multiple years.--
WITH StateYield AS (
    SELECT
        state_name,
        AVG(CASE WHEN Area > 0 THEN Production / Area ELSE NULL END) AS AverageYield
    FROM
        crop_details
    GROUP BY
        State_Name
)

SELECT
    State_name,
    AverageYield
FROM
    StateYield
ORDER BY
    AverageYield DESC
OFFSET 0 ROWS FETCH NEXT 6 ROWS ONLY; -- Replace @N with the number of top states you want

--4.calculates the variance in production across different crops and states. (tip: use VAR function).--
SELECT
    State_name,
    Crop,
    VAR(Production) AS ProductionVariance
FROM
    Crop_details
GROUP BY
    State_Name,
    Crop
ORDER BY
    State_Name,
    Crop;

select * from crop_details

--5.Identifies states that have the largest increase in cultivated area for a specific crop between two years--
DECLARE @CropName NVARCHAR(100) = 'Sugarcane'; -- Replace with the specific crop name
DECLARE @Year1 INT = 2008; -- Replace with the first year
DECLARE @Year2 INT = 2011; -- Replace with the second year

WITH AreaChange AS (
    SELECT
        State_name,
        Crop,
        SUM(CASE WHEN Crop_Year = @Year1 THEN Area ELSE 0 END) AS AreaYear1,
        SUM(CASE WHEN Crop_Year = @Year2 THEN Area ELSE 0 END) AS AreaYear2
    FROM
        Crop_Details
    WHERE
        Crop = @CropName AND
        Crop_Year IN (@Year1, @Year2)
    GROUP BY
        State_Name, Crop
)

SELECT
    State_Name,
    (AreaYear2 - AreaYear1) AS AreaIncrease
FROM
    AreaChange
WHERE
    AreaYear2 > AreaYear1 -- Only include states with an increase
ORDER BY
    AreaIncrease 






