USE TrainingDB;
SET NOCOUNT ON;
DECLARE @EmpTarget INT = 300000, @TsTarget INT = 300000;

;WITH N AS (
    SELECT TOP (300000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects o1 CROSS JOIN sys.all_objects o2
)
INSERT INTO Employees (FirstName, LastName, DepartmentID, Salary, HireDate)
SELECT 'Employee' + CAST(n AS NVARCHAR), 'Surname' + CAST(n AS NVARCHAR),
       ABS(CHECKSUM(NEWID()) % 5) + 1,
       ROUND((20000 + ABS(CHECKSUM(NEWID())) % 60000), 2),
       DATEADD(day, ABS(CHECKSUM(NEWID())) % 1000, '2022-01-01')
FROM N;

DECLARE @maxEmp INT = (SELECT MAX(EmployeeID) FROM Employees);
;WITH N AS (
    SELECT TOP (300000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects o1 CROSS JOIN sys.all_objects o2
)
INSERT INTO Timesheets (EmployeeID, ProjectID, WorkDate, HoursWorked)
SELECT ABS(CHECKSUM(NEWID()) % @maxEmp) + 1,
       ABS(CHECKSUM(NEWID()) % 3) + 1,
       DATEADD(day, ABS(CHECKSUM(NEWID())) % 365, '2023-01-01'),
       ROUND(4 + ABS(CHECKSUM(NEWID())) % 5, 1)
FROM N;
GO
SELECT 'Employees' AS t, COUNT(*) c FROM Employees
UNION ALL SELECT 'Timesheets', COUNT(*) FROM Timesheets;
SELECT OBJECT_NAME(i.object_id) AS tbl, SUM(a.total_pages)*8/1024 AS MB
FROM sys.indexes i JOIN sys.partitions p ON i.object_id=p.object_id AND i.index_id=p.index_id
JOIN sys.allocation_units a ON p.partition_id=a.container_id
WHERE i.object_id IN (OBJECT_ID('Employees'),OBJECT_ID('Timesheets'))
GROUP BY OBJECT_NAME(i.object_id);
GO
