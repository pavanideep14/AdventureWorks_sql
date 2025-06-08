USE LevelCTaskDB;
-- ========================================
-- Level C SQL Tasks
-- SUBMITTED BY: PAVANI DEEP
-- Description: Solutions for all 20 SQL tasks
-- ========================================


-- ========================================
-- Task 1: Group Tasks into Projects
-- ========================================
-- Objective: Group tasks with consecutive dates into projects
-- Table: Projects(Task_ID, Start_Date, End_Date)
IF OBJECT_ID('Projects', 'U') IS NOT NULL
    DROP TABLE Projects;

CREATE TABLE Projects (
    Task_ID INT,
    Start_Date DATE,
    End_Date DATE
);
INSERT INTO Projects (Task_ID, Start_Date, End_Date) VALUES
(1, '2015-10-01', '2015-10-02'),
(2, '2015-10-02', '2015-10-03'),
(3, '2015-10-03', '2015-10-04'),
(4, '2015-10-13', '2015-10-14'),
(5, '2015-10-14', '2015-10-15'),
(6, '2015-10-28', '2015-10-29'),
(7, '2015-10-30', '2015-10-31');
WITH ProjectGroups AS (
    SELECT 
        Task_ID,
        Start_Date,
        End_Date,
        DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY Start_Date), Start_Date) AS grp
    FROM Projects
),
GroupedProjects AS (
    SELECT 
        MIN(Start_Date) AS project_start,
        MAX(End_Date) AS project_end,
        DATEDIFF(DAY, MIN(Start_Date), MAX(End_Date)) + 1 AS duration
    FROM ProjectGroups
    GROUP BY grp
)
SELECT 
    project_start,
    project_end
FROM GroupedProjects
ORDER BY duration ASC, project_start;



-- Drop if already exists
DROP TABLE IF EXISTS Students;
DROP TABLE IF EXISTS Friends;
DROP TABLE IF EXISTS Packages;

-- Create tables
CREATE TABLE Students (
    ID INT,
    Name VARCHAR(50)
);

CREATE TABLE Friends (
    ID INT,
    Friend_ID INT
);

CREATE TABLE Packages (
    ID INT,
    Salary FLOAT
);

-- Sample data
INSERT INTO Students VALUES
(1, 'Ashley'),
(2, 'Samantha'),
(3, 'Julia'),
(4, 'Scarlet');

INSERT INTO Friends VALUES
(1, 2),
(2, 3),
(3, 4),
(4, 1);

INSERT INTO Packages VALUES
(1, 15.00),
(2, 10.06),
(3, 18.50),
(4, 19.20);

-- ========================================
-- Task 2: Students Whose Best Friend Got a Higher Salary
-- ========================================
-- Objective: Find names of students whose best friend has a higher salary

SELECT s.Name
FROM Students s
JOIN Friends f ON s.ID = f.ID
JOIN Packages p1 ON s.ID = p1.ID
JOIN Packages p2 ON f.Friend_ID = p2.ID
WHERE p2.Salary > p1.Salary
ORDER BY p2.Salary;



-- Drop existing if needed
DROP TABLE IF EXISTS Functions;

-- Create table
CREATE TABLE Functions (
    Type VARCHAR(20),
    X INT,
    Y INT
);

-- Insert sample data
INSERT INTO Functions VALUES
('Integer', 20, 20),
('Integer', 20, 21),
('Integer', 21, 20),
('Integer', 22, 23),
('Integer', 23, 22),
('Integer', 20, 20);  -- duplicate (symmetric with itself)

-- ========================================
-- Task 3: Find Symmetric Pairs
-- ========================================
-- Objective: Return (X, Y) where both (X, Y) and (Y, X) exist

SELECT DISTINCT f1.X, f1.Y
FROM Functions f1
JOIN Functions f2
  ON f1.X = f2.Y AND f1.Y = f2.X
WHERE f1.X <= f1.Y
ORDER BY f1.X;





-- ========================================
-- Task 5: Daily Unique Hackers and Top Submitters
-- ========================================
-- Drop if needed
DROP TABLE IF EXISTS Contests, Colleges, Challenges, View_Stats, Submission_Stats;

CREATE TABLE Contests (
    contest_id VARCHAR(20),
    hacker_id INT,
    name VARCHAR(50)
);

CREATE TABLE Colleges (
    college_id INT,
    contest_id VARCHAR(20)
);

CREATE TABLE Challenges (
    challenge_id INT,
    college_id INT
);

CREATE TABLE View_Stats (
    challenge_id INT,
    total_views INT,
    total_unique_views INT
);

CREATE TABLE Submission_Stats (
    challenge_id INT,
    total_submissions INT,
    total_accepted_submissions INT
);

-- Insert sample contests
INSERT INTO Contests VALUES
('66406', 17973, 'Rose'),
('66556', 79153, 'Angela'),
('94828', 80275, 'Frank');

-- Colleges using contests
INSERT INTO Colleges VALUES
(11219, '66406'),
(32473, '66556'),
(56685, '94828');

-- Challenges at colleges
INSERT INTO Challenges VALUES
(47127, 11219),
(60292, 32473),
(72974, 56685);

-- View stats
INSERT INTO View_Stats VALUES
(47127, 26, 19),
(60292, 11, 10),
(72974, 41, 15);

-- Submission stats
INSERT INTO Submission_Stats VALUES
(47127, 85, 39),
(60292, 0, 0),
(72974, 150, 38);
-- ========================================
-- Task 4: Aggregate Contest Statistics
-- ========================================
-- Objective: Sum submissions and views for each contest used in college screening

SELECT 
    c.contest_id,
    c.hacker_id,
    c.name,
    SUM(COALESCE(ss.total_submissions, 0)) AS total_submissions,
    SUM(COALESCE(ss.total_accepted_submissions, 0)) AS total_accepted_submissions,
    SUM(COALESCE(vs.total_views, 0)) AS total_views,
    SUM(COALESCE(vs.total_unique_views, 0)) AS total_unique_views
FROM Contests c
JOIN Colleges co ON c.contest_id = co.contest_id
JOIN Challenges ch ON co.college_id = ch.college_id
LEFT JOIN Submission_Stats ss ON ch.challenge_id = ss.challenge_id
LEFT JOIN View_Stats vs ON ch.challenge_id = vs.challenge_id
GROUP BY c.contest_id, c.hacker_id, c.name
HAVING
    SUM(COALESCE(ss.total_submissions, 0)) > 0 OR
    SUM(COALESCE(ss.total_accepted_submissions, 0)) > 0 OR
    SUM(COALESCE(vs.total_views, 0)) > 0 OR
    SUM(COALESCE(vs.total_unique_views, 0)) > 0
ORDER BY c.contest_id;




-- DROP if exists
DROP TABLE IF EXISTS Hackers;
DROP TABLE IF EXISTS Submissions;

-- Create tables
CREATE TABLE Hackers (
    hacker_id INT,
    name VARCHAR(50)
);

CREATE TABLE Submissions (
    submission_id INT,
    hacker_id INT,
    submission_date DATE,
    score INT
);
INSERT INTO Hackers VALUES
(20703, 'Angela'),
(36396, 'Frank'),
(79722, 'Michael');

INSERT INTO Submissions VALUES
(8494, 20703, '2016-03-01', 0),
(23965, 79722, '2016-03-01', 60),
(30173, 36396, '2016-03-01', 70),
(38740, 20703, '2016-03-02', 0),
(42788, 79722, '2016-03-02', 25),
(44399, 79722, '2016-03-02', 80),
(45440, 20703, '2016-03-03', 0),
(48750, 36396, '2016-03-03', 70),
(50273, 79722, '2016-03-03', 5);

SELECT
  submission_date,
  COUNT(DISTINCT hacker_id) AS unique_hackers
FROM Submissions
GROUP BY submission_date;
--PART2
WITH RankedHackerSubmissions AS (
    SELECT
        submission_date,
        hacker_id,
        COUNT(*) AS total_subs,
        ROW_NUMBER() OVER (
            PARTITION BY submission_date
            ORDER BY COUNT(*) DESC, hacker_id
        ) AS rn
    FROM Submissions
    GROUP BY submission_date, hacker_id
)
SELECT
    submission_date,
    hacker_id,
    total_subs
FROM RankedHackerSubmissions
WHERE rn = 1
ORDER BY submission_date;





-- ========================================
-- Task 6: Manhattan Distance Between Extremes
-- ========================================
-- Objective:
-- Find the Manhattan Distance between:
--   - Point A = (min LAT_N, min LONG_W)
--   - Point B = (max LAT_N, max LONG_W)
-- Manhattan Distance = |lat1 - lat2| + |long1 - long2|
-- Round to 4 decimal places

-- DROP if table exists to avoid errors
IF OBJECT_ID('Station', 'U') IS NOT NULL
    DROP TABLE Station;

-- Create the Station table
CREATE TABLE Station (
    LAT_N FLOAT,
    LONG_W FLOAT
);

-- OPTIONAL: Sample data for testing
-- Uncomment the below INSERTs to test

INSERT INTO Station (LAT_N, LONG_W) VALUES
(10.0, 20.0),
(20.0, 30.0),
(40.0, 15.0),
(60.0, 50.0);

-- Final Query
SELECT
  ROUND(
    ABS(MIN(LAT_N) - MAX(LAT_N)) +
    ABS(MIN(LONG_W) - MAX(LONG_W)),
    4
  ) AS manhattan_distance
FROM Station;






-- ========================================
-- Task 7: Prime Numbers ≤ 1000 (joined with &)
-- ========================================
-- Objective: Print all prime numbers ≤ 1000 on one line separated by '&'
WITH Numbers AS (
    SELECT 2 AS n
    UNION ALL
    SELECT n + 1 FROM Numbers WHERE n + 1 <= 1000
),
Primes AS (
    SELECT n
    FROM Numbers
    WHERE NOT EXISTS (
        SELECT 1
        FROM Numbers AS Div
        WHERE Div.n < Numbers.n AND Numbers.n % Div.n = 0 AND Div.n > 1
    )
)
SELECT STRING_AGG(CAST(n AS VARCHAR), '&') AS Prime_List
FROM Primes
OPTION (MAXRECURSION 1000);






-- ========================================
-- Task 8: Pivot Occupations by Name
-- ========================================

-- Drop table if exists
IF OBJECT_ID('Occupations', 'U') IS NOT NULL
    DROP TABLE Occupations;

-- Create table
CREATE TABLE Occupations (
    Name VARCHAR(50),
    Occupation VARCHAR(50)
);

-- Sample Data (for testing)
INSERT INTO Occupations VALUES
('Samantha', 'Doctor'),
('Julia', 'Actor'),
('Priya', 'Singer'),
('Meera', 'Singer'),
('Ashley', 'Professor'),
('Ketty', 'Professor'),
('Christeen', 'Professor'),
('Jane', 'Actor'),
('Jenny', 'Doctor'),
('Maria', 'Actor');

-- Pivot Query
WITH Ranked AS (
    SELECT 
        Name,
        Occupation,
        ROW_NUMBER() OVER (PARTITION BY Occupation ORDER BY Name) AS rn
    FROM Occupations
)
SELECT
    MAX(CASE WHEN Occupation = 'Doctor' THEN Name END) AS Doctor,
    MAX(CASE WHEN Occupation = 'Professor' THEN Name END) AS Professor,
    MAX(CASE WHEN Occupation = 'Singer' THEN Name END) AS Singer,
    MAX(CASE WHEN Occupation = 'Actor' THEN Name END) AS Actor
FROM Ranked
GROUP BY rn
ORDER BY rn;





-- DROP TABLE IF EXISTS BST;
IF OBJECT_ID('BST', 'U') IS NOT NULL
    DROP TABLE BST;

CREATE TABLE BST (
    N INT,
    P INT
);

INSERT INTO BST VALUES
(1, 2),
(3, 2),
(6, 8),
(9, 8),
(2, 5),
(8, 5),
(5, NULL);
-- ========================================
-- Task 9: Binary Tree Node Types
-- ========================================
-- Objective: Classify nodes as Root, Inner, or Leaf

SELECT 
    b.N,
    CASE 
        WHEN b.P IS NULL THEN 'Root'
        WHEN c.N IS NULL THEN 'Leaf'
        ELSE 'Inner'
    END AS Node_Type
FROM BST b
LEFT JOIN BST c ON b.N = c.P
ORDER BY b.N;





-- DROP TABLE IF EXISTS Company, Lead_Manager, Senior_Manager, Manager, Employee;
-- Drop all hierarchy tables if they exist
IF OBJECT_ID('Employee', 'U') IS NOT NULL DROP TABLE Employee;
IF OBJECT_ID('Manager', 'U') IS NOT NULL DROP TABLE Manager;
IF OBJECT_ID('Senior_Manager', 'U') IS NOT NULL DROP TABLE Senior_Manager;
IF OBJECT_ID('Lead_Manager', 'U') IS NOT NULL DROP TABLE Lead_Manager;
IF OBJECT_ID('Company', 'U') IS NOT NULL DROP TABLE Company;





-- ========================================
-- Task 11: Students Whose Best Friend Got Better Salary
-- ========================================
-- Objective: Find students whose best friend's salary is higher than theirs.

SELECT s.Name
FROM Students s
JOIN Friends f ON s.ID = f.ID
JOIN Packages p1 ON s.ID = p1.ID
JOIN Packages p2 ON f.Friend_ID = p2.ID
WHERE p2.Salary > p1.Salary
ORDER BY p2.Salary;


CREATE TABLE Company (
    company_code VARCHAR(10),
    founder VARCHAR(50)
);

CREATE TABLE Lead_Manager (
    lead_manager_code VARCHAR(10),
    company_code VARCHAR(10)
);

CREATE TABLE Senior_Manager (
    senior_manager_code VARCHAR(10),
    lead_manager_code VARCHAR(10),
    company_code VARCHAR(10)
);

CREATE TABLE Manager (
    manager_code VARCHAR(10),
    senior_manager_code VARCHAR(10),
    lead_manager_code VARCHAR(10),
    company_code VARCHAR(10)
);

CREATE TABLE Employee (
    employee_code VARCHAR(10),
    manager_code VARCHAR(10),
    senior_manager_code VARCHAR(10),
    lead_manager_code VARCHAR(10),
    company_code VARCHAR(10)
);

-- Insert some test data
INSERT INTO Company VALUES ('C1', 'Alice'), ('C2', 'Bob');

INSERT INTO Lead_Manager VALUES ('L1', 'C1'), ('L2', 'C1'), ('L3', 'C2');

INSERT INTO Senior_Manager VALUES 
('S1', 'L1', 'C1'), 
('S2', 'L2', 'C1'), 
('S3', 'L3', 'C2');

INSERT INTO Manager VALUES 
('M1', 'S1', 'L1', 'C1'),
('M2', 'S2', 'L2', 'C1'),
('M3', 'S3', 'L3', 'C2');

INSERT INTO Employee VALUES 
('E1', 'M1', 'S1', 'L1', 'C1'),
('E2', 'M2', 'S2', 'L2', 'C1'),
('E3', 'M3', 'S3', 'L3', 'C2');
-- ========================================
-- Task 10: Company Hierarchy Summary
-- ========================================
-- Objective: For each company, count the number of each type of role

SELECT
    c.company_code,
    c.founder,
    COUNT(DISTINCT lm.lead_manager_code) AS lead_manager_count,
    COUNT(DISTINCT sm.senior_manager_code) AS senior_manager_count,
    COUNT(DISTINCT m.manager_code) AS manager_count,
    COUNT(DISTINCT e.employee_code) AS employee_count
FROM Company c
LEFT JOIN Lead_Manager lm ON c.company_code = lm.company_code
LEFT JOIN Senior_Manager sm ON c.company_code = sm.company_code
LEFT JOIN Manager m ON c.company_code = m.company_code
LEFT JOIN Employee e ON c.company_code = e.company_code
GROUP BY c.company_code, c.founder
ORDER BY c.company_code;





-- DROP TABLE IF EXISTS EmployeeCosts;
IF OBJECT_ID('EmployeeCosts', 'U') IS NOT NULL
    DROP TABLE EmployeeCosts;
CREATE TABLE EmployeeCosts (
    emp_id INT,
    location VARCHAR(50),
    cost FLOAT
);

INSERT INTO EmployeeCosts VALUES
(1, 'India', 50000),
(2, 'India', 45000),
(3, 'International', 120000),
(4, 'India', 60000),
(5, 'International', 100000);
-- ========================================
-- Task 12: Cost Ratio (India vs International)
-- ========================================
-- Objective: Show percentage of cost in India vs total global cost

SELECT 
    ROUND(
        SUM(CASE WHEN location = 'India' THEN cost ELSE 0 END) * 100.0 /
        SUM(cost),
        2
    ) AS india_cost_ratio_percentage
FROM EmployeeCosts;





-- DROP TABLE IF EXISTS BU_Costs, BU_Revenue;
IF OBJECT_ID('BU_Costs', 'U') IS NOT NULL DROP TABLE BU_Costs;
IF OBJECT_ID('BU_Revenue', 'U') IS NOT NULL DROP TABLE BU_Revenue;

CREATE TABLE BU_Costs (
    bu VARCHAR(50),
    month DATE,
    cost FLOAT
);

CREATE TABLE BU_Revenue (
    bu VARCHAR(50),
    month DATE,
    revenue FLOAT
);

-- Sample data
INSERT INTO BU_Costs VALUES
('Finance', '2024-01-01', 80000),
('Finance', '2024-02-01', 90000),
('IT', '2024-01-01', 150000),
('IT', '2024-02-01', 160000);

INSERT INTO BU_Revenue VALUES
('Finance', '2024-01-01', 200000),
('Finance', '2024-02-01', 180000),
('IT', '2024-01-01', 300000),
('IT', '2024-02-01', 350000);
-- ========================================
-- Task 13: BU-wise Cost to Revenue Ratio (Month-wise)
-- ========================================
-- Objective: For each BU and Month, compute (Cost * 100) / Revenue
SELECT 
    c.bu,
    FORMAT(c.month, 'yyyy-MM') AS month,
    ROUND(c.cost * 100.0 / r.revenue, 2) AS cost_revenue_ratio_pct
FROM BU_Costs c
JOIN BU_Revenue r ON c.bu = r.bu AND c.month = r.month
ORDER BY c.bu, c.month;





-- ========================================
-- Task 14: Count Headcount per Sub-Band (No JOINs/Subqueries)
-- ========================================

-- Drop if exists
IF OBJECT_ID('EmployeeBand', 'U') IS NOT NULL
    DROP TABLE EmployeeBand;

-- Create the table
CREATE TABLE EmployeeBand (
    emp_name VARCHAR(50),
    band VARCHAR(10),
    sub_band VARCHAR(10)
);

-- Sample data (optional)
INSERT INTO EmployeeBand VALUES
('Amit', 'B1', 'B1A'),
('Neha', 'B1', 'B1A'),
('John', 'B1', 'B1B'),
('Sana', 'B2', 'B2A'),
('Tina', 'B2', 'B2A'),
('Leo', 'B2', 'B2B');

SELECT
    sub_band,
    COUNT(*) AS headcount
FROM EmployeeBand
GROUP BY sub_band
ORDER BY sub_band;





-- ========================================
-- Task 15: BU-wise Top Salary Using RANK()
-- ========================================
-- Objective: List highest-paid employee(s) in each BU using RANK()

-- Drop table if it exists
IF OBJECT_ID('EmployeeSalary', 'U') IS NOT NULL
    DROP TABLE EmployeeSalary;

-- Create table
CREATE TABLE EmployeeSalary (
    emp_name VARCHAR(50),
    bu VARCHAR(50),
    salary FLOAT
);

-- Sample data (optional)
INSERT INTO EmployeeSalary VALUES
('Amit', 'Finance', 90000),
('Neha', 'Finance', 90000),
('John', 'Finance', 85000),
('Tina', 'IT', 120000),
('Leo', 'IT', 110000),
('Sara', 'HR', 95000);

-- Query using RANK()
WITH RankedSalaries AS (
    SELECT 
        emp_name,
        bu,
        salary,
        RANK() OVER (PARTITION BY bu ORDER BY salary DESC) AS rnk
    FROM EmployeeSalary
)
SELECT emp_name, bu, salary
FROM RankedSalaries
WHERE rnk = 1
ORDER BY bu;





-- ========================================
-- Task 16: Band-wise Monthly Spend in INR
-- ========================================
-- Objective: Convert cost to INR and sum monthly cost per band

-- Drop tables if exist
IF OBJECT_ID('EmployeeFinance', 'U') IS NOT NULL DROP TABLE EmployeeFinance;
IF OBJECT_ID('ExchangeRates', 'U') IS NOT NULL DROP TABLE ExchangeRates;

-- Re-create tables
CREATE TABLE EmployeeFinance (
    emp_name VARCHAR(50),
    band VARCHAR(10),
    month DATE,
    cost FLOAT,
    currency VARCHAR(10)
);

CREATE TABLE ExchangeRates (
    currency VARCHAR(10),
    rate_to_inr FLOAT
);

-- Optional test data
INSERT INTO EmployeeFinance VALUES
('Amit', 'B1', '2024-01-01', 1000, 'USD'),
('Neha', 'B1', '2024-01-01', 900, 'USD'),
('John', 'B2', '2024-01-01', 700, 'EUR'),
('Sana', 'B1', '2024-02-01', 1100, 'USD'),
('Leo',  'B2', '2024-02-01', 800, 'EUR');

INSERT INTO ExchangeRates VALUES
('USD', 83.0),
('EUR', 90.0);

-- Final INR Spend Query
SELECT
    ef.band,
    FORMAT(ef.month, 'yyyy-MM') AS month,
    ROUND(SUM(ef.cost * er.rate_to_inr), 2) AS total_spend_inr
FROM EmployeeFinance ef
JOIN ExchangeRates er ON ef.currency = er.currency
GROUP BY ef.band, ef.month
ORDER BY ef.band, ef.month;





-- ========================================
-- Task 17: BU-wise Monthly Joiners
-- ========================================
-- Objective: For each BU and month, count the number of joiners

-- Drop table if it exists
IF OBJECT_ID('EmployeeJoiners', 'U') IS NOT NULL
    DROP TABLE EmployeeJoiners;

-- Create table
CREATE TABLE EmployeeJoiners (
    emp_name VARCHAR(50),
    bu VARCHAR(50),
    join_date DATE
);

-- Optional test data
INSERT INTO EmployeeJoiners VALUES
('Amit', 'IT', '2024-01-15'),
('Neha', 'IT', '2024-01-20'),
('John', 'HR', '2024-02-01'),
('Sana', 'Finance', '2024-02-05'),
('Leo', 'IT', '2024-02-10'),
('Tina', 'Finance', '2024-01-25');

-- Final Query
SELECT 
    bu,
    FORMAT(join_date, 'yyyy-MM') AS month,
    COUNT(*) AS joiners
FROM EmployeeJoiners
GROUP BY bu, FORMAT(join_date, 'yyyy-MM')
ORDER BY bu, month;






-- ========================================
-- Task 18: BU-wise Active Employees per Month
-- ========================================
-- Objective: Count how many employees were active in each BU in each month

-- Drop table
IF OBJECT_ID('EmployeeLifespan', 'U') IS NOT NULL
    DROP TABLE EmployeeLifespan;

-- Create table
CREATE TABLE EmployeeLifespan (
    emp_name VARCHAR(50),
    bu VARCHAR(50),
    join_date DATE,
    exit_date DATE
);

-- Optional sample data
INSERT INTO EmployeeLifespan VALUES
('Amit', 'IT', '2024-01-01', '2024-03-10'),
('Neha', 'IT', '2024-02-15', '2024-04-01'),
('John', 'HR', '2024-01-20', '2024-01-31'),
('Sana', 'Finance', '2024-01-10', '2024-02-15'),
('Leo', 'Finance', '2024-02-01', '2024-03-05');

-- Generate months (recursive CTE)
WITH Months AS (
    SELECT CAST('2024-01-01' AS DATE) AS month_start
    UNION ALL
    SELECT DATEADD(MONTH, 1, month_start)
    FROM Months
    WHERE month_start < '2024-04-01'
)
SELECT 
    m.month_start AS month,
    e.bu,
    COUNT(*) AS active_employees
FROM Months m
JOIN EmployeeLifespan e 
    ON m.month_start BETWEEN 
       DATEFROMPARTS(YEAR(e.join_date), MONTH(e.join_date), 1)
       AND DATEFROMPARTS(YEAR(e.exit_date), MONTH(e.exit_date), 1)
GROUP BY m.month_start, e.bu
ORDER BY m.month_start, e.bu
OPTION (MAXRECURSION 100);




-- ========================================
-- Task 19: 7-Day Rolling Joiners
-- ========================================
-- Objective: For each join date, count how many employees joined
-- in the previous 7 days (inclusive of the current date)

-- Drop table if it exists
IF OBJECT_ID('JoinLog', 'U') IS NOT NULL
    DROP TABLE JoinLog;

-- Create table
CREATE TABLE JoinLog (
    emp_name VARCHAR(50),
    join_date DATE
);

-- Sample data
INSERT INTO JoinLog VALUES
('Amit', '2024-01-01'),
('Neha', '2024-01-02'),
('John', '2024-01-04'),
('Tina', '2024-01-05'),
('Leo', '2024-01-08'),
('Sara', '2024-01-09'),
('Ravi', '2024-01-10');

-- Final Query
SELECT 
    j1.join_date,
    COUNT(j2.emp_name) AS rolling_joiners_7_day
FROM JoinLog j1
JOIN JoinLog j2
  ON j2.join_date BETWEEN DATEADD(DAY, -6, j1.join_date) AND j1.join_date
GROUP BY j1.join_date
ORDER BY j1.join_date;





-- ========================================
-- Task 20: Weekly BU Cost Report Using CROSS JOIN
-- ========================================
-- Objective: Report cost per BU per week; include BU-week combinations even if no cost exists

-- Drop tables if exist
IF OBJECT_ID('WeeklyCost', 'U') IS NOT NULL DROP TABLE WeeklyCost;
IF OBJECT_ID('BUList', 'U') IS NOT NULL DROP TABLE BUList;
IF OBJECT_ID('WeekList', 'U') IS NOT NULL DROP TABLE WeekList;

-- Create tables
CREATE TABLE BUList (
    bu VARCHAR(50)
);

CREATE TABLE WeekList (
    week_start DATE
);

CREATE TABLE WeeklyCost (
    bu VARCHAR(50),
    week_start DATE,
    cost FLOAT
);

-- Insert data
INSERT INTO BUList VALUES ('IT'), ('HR'), ('Finance');

INSERT INTO WeekList VALUES
('2024-01-01'), ('2024-01-08'), ('2024-01-15');

INSERT INTO WeeklyCost VALUES
('IT', '2024-01-01', 50000),
('HR', '2024-01-08', 30000),
('Finance', '2024-01-08', 40000);

-- Final report query
SELECT 
    b.bu,
    w.week_start,
    c.cost
FROM BUList b
CROSS JOIN WeekList w
LEFT JOIN WeeklyCost c ON c.bu = b.bu AND c.week_start = w.week_start
ORDER BY b.bu, w.week_start;
