CREATE TABLE hr_data (
    Age INT,
    Attrition VARCHAR(10),
    BusinessTravel VARCHAR(50),
    DailyRate INT,
    Department VARCHAR(50),
    DistanceFromHome INT,
    Education INT,
    EducationField VARCHAR(50),
    EmployeeCount INT,
    EmployeeNumber INT,
    EnvironmentSatisfaction INT,
    Gender VARCHAR(10),
    HourlyRate INT,
    JobInvolvement INT,
    JobLevel INT,
    JobRole VARCHAR(50),
    JobSatisfaction INT,
    MaritalStatus VARCHAR(20),
    MonthlyIncome INT,
    MonthlyRate INT,
    NumCompaniesWorked INT,
    Over18 VARCHAR(5),
    OverTime VARCHAR(10),
    PercentSalaryHike INT,
    PerformanceRating INT,
    RelationshipSatisfaction INT,
    StandardHours INT,
    StockOptionLevel INT,
    TotalWorkingYears INT,
    TrainingTimesLastYear INT,
    WorkLifeBalance INT,
    YearsAtCompany INT,
    YearsInCurrentRole INT,
    YearsSinceLastPromotion INT,
    YearsWithCurrManager INT
);

SELECT * FROM hr_data;

--duplicate rows--

SELECT EmployeeNumber, COUNT(*)
FROM hr_data
GROUP BY EmployeeNumber
HAVING COUNT(*) > 1;


--overall attrition--

SELECT 
    COUNT(*) AS total_employees,
    COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) AS employees_left,
    ROUND(
        COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2
    ) AS attrition_rate
FROM hr_data;

--Department wise attrition--

SELECT 
    Department,
    COUNT(*) AS total_employees,
    COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) AS employees_left
FROM hr_data
GROUP BY Department
ORDER BY employees_left DESC;


--gender-wise atrrition--

SELECT 
    Gender,
    COUNT(*) AS total_employees,
    COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) AS employees_left
FROM hr_data
GROUP BY Gender;

--age_group wise attrition--

SELECT
    CASE 
        WHEN Age < 30 THEN 'Below 30'
        WHEN Age BETWEEN 30 AND 40 THEN '30-40'
        ELSE 'Above 40'
    END AS age_group,
    COUNT(*) AS total_employees,
    COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) AS employees_left
FROM hr_data
GROUP BY age_group
ORDER BY employees_left DESC;


--Salary ka attrition pe kya effect hai?--

SELECT
    CASE
        WHEN MonthlyIncome < 5000 THEN 'Low Salary'
        WHEN MonthlyIncome BETWEEN 5000 AND 10000 THEN 'Medium Salary'
        ELSE 'High Salary'
    END AS salary_group,
    COUNT(*) AS total_employees,
    COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) AS employees_left
FROM hr_data
GROUP BY salary_group
ORDER BY employees_left DESC;


--Experience (YearsAtCompany) ka impact--

SELECT
    CASE
        WHEN YearsAtCompany < 2 THEN 'Less than 2 years'
        WHEN YearsAtCompany BETWEEN 2 AND 5 THEN '2-5 years'
        ELSE 'More than 5 years'
    END AS experience_group,
    COUNT(*) AS total_employees,
    COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) AS employees_left
FROM hr_data
GROUP BY experience_group
ORDER BY employees_left DESC;


--OverTime aur attrition ka relation--

SELECT 
    OverTime,
    COUNT(*) AS Total_Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Count,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Attrition_Rate_Percentage
FROM hr_Data
GROUP BY OverTime;


--JobRole-wise attrition--

SELECT
    JobRole,
    COUNT(*) AS total_employees,
    COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) AS employees_left
FROM hr_data
GROUP BY JobRole
ORDER BY employees_left DESC;


--Promotion delay ka attrition pe effect?--

SELECT 
    CASE 
        WHEN YearsSinceLastPromotion <= 2 THEN '0-2 Years (Recent)'
        WHEN YearsSinceLastPromotion BETWEEN 3 AND 5 THEN '3-5 Years (Mid Delay)'
        WHEN YearsSinceLastPromotion BETWEEN 6 AND 10 THEN '6-10 Years (High Delay)'
        ELSE '10+ Years (Extreme)'
    END AS Promotion_Gap,
    COUNT(*) AS Total_Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Count,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Attrition_Rate
FROM hr_Data
GROUP BY 1
ORDER BY MIN(YearsSinceLastPromotion);


--High-Risk Employee Segments--

WITH Employee_Risk_Profiling AS (
    SELECT 
        EmployeeNumber,
        -- Risk score calculate ho raha hai
        (
            (CASE WHEN OverTime = 'Yes' THEN 1 ELSE 0 END) +
            (CASE WHEN JobSatisfaction <= 2 THEN 1 ELSE 0 END) +
            (CASE WHEN EnvironmentSatisfaction <= 2 THEN 1 ELSE 0 END) +
            (CASE WHEN DistanceFromHome > 15 THEN 1 ELSE 0 END) +
            (CASE WHEN YearsSinceLastPromotion >= 3 THEN 1 ELSE 0 END) +
            (CASE WHEN MonthlyIncome < (SELECT AVG(MonthlyIncome) FROM hr_data) THEN 1 ELSE 0 END)
        ) AS Total_Risk_Points,
        MonthlyIncome
    FROM hr_data
    WHERE Attrition = 'No'
)
SELECT 
    CASE 
        WHEN Total_Risk_Points >= 4 THEN 'Extreme Risk (Retention Plan Needed)'
        WHEN Total_Risk_Points = 3 THEN 'High Risk (Monitor Closely)'
        WHEN Total_Risk_Points = 2 THEN 'Moderate Risk (Standard Engagement)'
        ELSE 'Low Risk (Loyal/Satisfied)'
    END AS Risk_Category,
    COUNT(*) AS Employee_Count,
    ROUND(AVG(MonthlyIncome), 2) as Avg_Salary,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hr_data WHERE Attrition = 'No'), 2) AS Percentage
FROM Employee_Risk_Profiling
GROUP BY 1  -- Yahan '1' ka matlab hai Risk_Category
ORDER BY MIN(Total_Risk_Points) DESC; -- Error Fixed: MIN() use kiya taaki sorting logical rahe


--Kya naye employees (early cohorts) zyada attrition dikha rahe hain?--

SELECT
    YearsAtCompany AS cohort_years,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
    ROUND(
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS attrition_rate
FROM hr_data
GROUP BY YearsAtCompany
ORDER BY YearsAtCompany;

--Kaunsa employee profile sabse zyada risk pe hai?--

SELECT
    Department,
    JobRole,
    OverTime,
    COUNT(*) AS total_emp,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count
FROM hr_data
GROUP BY Department, JobRole, OverTime
ORDER BY attrition_count DESC;


--Kya hum apne top-rated employees (PerformanceRating) ko kho rahe 
--hain kyunki unhe promotion ya hike nahi mil raha?--


SELECT 
    PerformanceRating,
    Attrition,
    COUNT(*) AS Emp_Count,
    ROUND(AVG(PercentSalaryHike), 2) AS Avg_Hike,
    ROUND(AVG(YearsSinceLastPromotion), 2) AS Avg_Promotion_Delay
FROM hr_data
WHERE PerformanceRating >= 3
GROUP BY PerformanceRating, Attrition
ORDER BY PerformanceRating, Attrition;

--Kya Overtime karne waale employees ka WorkLifeBalance aur JobSatisfaction itna kam 
--hai ki wo attrition ki taraf ja rahe hain?--

SELECT 
    OverTime,
    ROUND(AVG(WorkLifeBalance),2) AS Avg_WorkLife,
    ROUND(AVG(JobSatisfaction),2) AS Avg_Satisfaction,
    ROUND(COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) * 100.0 / COUNT(*),2) AS Attrition_Rate
FROM hr_data
GROUP BY OverTime;


--Ek hi JobLevel par, kya Attrition un logo ka zyada hai jinki MonthlyIncome 
--us level ki average income se kam hai?

WITH LevelAvg AS (
    SELECT JobLevel, AVG(MonthlyIncome) as AvgIncome 
    FROM hr_data GROUP BY JobLevel
)
SELECT 
    h.JobLevel,
    COUNT(*) AS Low_Pay_Exits
FROM hr_data h
JOIN LevelAvg la ON h.JobLevel = la.JobLevel
WHERE h.Attrition = 'Yes' AND h.MonthlyIncome < la.AvgIncome
GROUP BY h.JobLevel;

--The New Manager Strain--

SELECT 
    CASE WHEN YearsWithCurrManager < 1 THEN 'New Manager (<1yr)' 
         ELSE 'Stable Manager (>1yr)' END AS Manager_Tenure,
    COUNT(*) AS Total_Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Total_Attritions
FROM hr_data
GROUP BY 1;


--Kya door se aane waale log (DistanceFromHome) 
--kam EnvironmentSatisfaction hone par jaldi chhod dete hain?--

SELECT 
    CASE WHEN DistanceFromHome > 15 THEN 'Far' ELSE 'Near' END AS Commute_Category,
    EnvironmentSatisfaction,
    COUNT(*) AS Total,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Exits
FROM hr_data
GROUP BY 1, 2
ORDER BY 1, 2;

--The "Stagnant High-Performer" Analysis--

SELECT 
    PerformanceRating,
   ROUND(AVG(YearsSinceLastPromotion),2) AS Avg_Years_Wait,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Attrition_Rate
FROM hr_Data
GROUP BY PerformanceRating
ORDER BY PerformanceRating DESC;


select * from hr_data;

--Kya BusinessTravel (zyada safar) Married logon ko zyada pareshan kar raha hai ya Single logon ko?--

SELECT 
    MaritalStatus,
    BusinessTravel,
    COUNT(*) AS Total,
    ROUND(AVG(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100, 2) AS Attrition_Rate
FROM hr_data
GROUP BY MaritalStatus, BusinessTravel
ORDER BY Attrition_Rate DESC;


--Kya log sirf salary hike (PercentSalaryHike) se rukte hain, 
--ya StockOptionLevel (ownership) unhe zyada long-term tak rokta hai?

SELECT 
    StockOptionLevel,
    AVG(PercentSalaryHike) AS Avg_Hike,
    ROUND(AVG(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100, 2) AS Attrition_Rate
FROM hr_data
GROUP BY StockOptionLevel
ORDER BY StockOptionLevel;


--The "Investment Leak" (Training vs. Attrition)--

SELECT 
    TrainingTimesLastYear,
    COUNT(*) AS Total_Employees,
    ROUND(AVG(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100, 2) AS Attrition_Rate
FROM hr_data
GROUP BY TrainingTimesLastYear
ORDER BY TrainingTimesLastYear;

--Kya aapke high-performers (PerformanceRating) actually company ke saath engaged hain (JobInvolvement)?--

SELECT 
    PerformanceRating,
    JobInvolvement,
    COUNT(*) AS Total_Employees,
    ROUND(AVG(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100, 2) AS Attrition_Rate
FROM hr_data
GROUP BY PerformanceRating, JobInvolvement
ORDER BY PerformanceRating DESC, JobInvolvement ASC;

--Income vs. Distance (The "Worth It?" Factor)--

SELECT 
    CASE WHEN MonthlyIncome < 5000 THEN 'Low Income' ELSE 'High Income' END AS Income_Group,
    CASE WHEN DistanceFromHome > 15 THEN 'Far' ELSE 'Near' END AS Distance_Group,
    COUNT(*) AS Total,
	sum(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) as Attition_count,
    ROUND(AVG(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100, 2) AS Attrition_Rate
FROM hr_data
GROUP BY 1, 2
ORDER BY 5 DESC;

--Salary vs. Market Average (Equity Gap)--

WITH AvgSalaries AS (
    SELECT JobLevel, AVG(MonthlyIncome) AS LevelAvg FROM hr_data GROUP BY JobLevel
)
SELECT 
    e.JobLevel,
    COUNT(CASE WHEN e.MonthlyIncome < a.LevelAvg AND e.Attrition = 'Yes' THEN 1 END) AS Underpaid_Attritions,
    COUNT(CASE WHEN e.MonthlyIncome >= a.LevelAvg AND e.Attrition = 'Yes' THEN 1 END) AS Overpaid_Attritions
FROM hr_data e
JOIN AvgSalaries a ON e.JobLevel = a.JobLevel
GROUP BY e.JobLevel;
 






















