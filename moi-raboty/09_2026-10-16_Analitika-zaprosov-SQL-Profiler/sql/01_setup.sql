IF DB_ID('TrainingDB') IS NOT NULL
BEGIN
    ALTER DATABASE TrainingDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE TrainingDB;
END
GO
CREATE DATABASE TrainingDB;
GO
USE TrainingDB;
GO
CREATE TABLE Departments (
    DepartmentID   INT PRIMARY KEY IDENTITY(1,1),
    DepartmentName NVARCHAR(100) NOT NULL
);
CREATE TABLE Employees (
    EmployeeID   INT PRIMARY KEY IDENTITY(1,1),
    FirstName    NVARCHAR(50),
    LastName     NVARCHAR(50),
    DepartmentID INT FOREIGN KEY REFERENCES Departments(DepartmentID),
    Salary       DECIMAL(10,2),
    HireDate     DATE
);
CREATE TABLE Projects (
    ProjectID   INT PRIMARY KEY IDENTITY(1,1),
    ProjectName NVARCHAR(100),
    StartDate   DATE,
    EndDate     DATE
);
CREATE TABLE Timesheets (
    TimesheetID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID  INT FOREIGN KEY REFERENCES Employees(EmployeeID),
    ProjectID   INT FOREIGN KEY REFERENCES Projects(ProjectID),
    WorkDate    DATE,
    HoursWorked DECIMAL(5,2)
);
GO
INSERT INTO Departments (DepartmentName) VALUES ('HR'),('Finance'),('IT'),('Sales'),('Marketing');
WITH N AS (
    SELECT TOP 500 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.objects o1 CROSS JOIN sys.objects o2
)
INSERT INTO Employees (FirstName, LastName, DepartmentID, Salary, HireDate)
SELECT 'Employee' + CAST(n AS NVARCHAR), 'Surname' + CAST(n AS NVARCHAR),
       ABS(CHECKSUM(NEWID()) % 5) + 1,
       ROUND((20000 + ABS(CHECKSUM(NEWID())) % 60000), 2),
       DATEADD(day, ABS(CHECKSUM(NEWID())) % 1000, '2022-01-01')
FROM N;
INSERT INTO Projects (ProjectName, StartDate, EndDate) VALUES
('Project Alpha','2023-01-01','2024-01-01'),
('Project Beta','2023-03-01','2024-06-01'),
('Project Gamma','2023-06-01','2024-12-01');
WITH N AS (
    SELECT TOP 2000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.objects o1 CROSS JOIN sys.objects o2
)
INSERT INTO Timesheets (EmployeeID, ProjectID, WorkDate, HoursWorked)
SELECT ABS(CHECKSUM(NEWID()) % 500) + 1,
       ABS(CHECKSUM(NEWID()) % 3) + 1,
       DATEADD(day, ABS(CHECKSUM(NEWID())) % 365, '2023-01-01'),
       ROUND(4 + ABS(CHECKSUM(NEWID())) % 5, 1)
FROM N;
GO
SELECT 'Departments' AS TableName, COUNT(*) AS Rows_ FROM Departments
UNION ALL SELECT 'Employees', COUNT(*) FROM Employees
UNION ALL SELECT 'Projects', COUNT(*) FROM Projects
UNION ALL SELECT 'Timesheets', COUNT(*) FROM Timesheets;
GO
