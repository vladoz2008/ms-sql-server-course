/* ПР24. Дополнительно — корректные (покрывающие) индексы */
USE TrainingDB;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Employees_Dept_Salary')
   CREATE INDEX IX_Employees_Dept_Salary ON Employees(DepartmentID) INCLUDE (Salary);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Employees_Salary_Covering')
   CREATE INDEX IX_Employees_Salary_Covering ON Employees(Salary) INCLUDE (LastName);
GO

/* Запрос C — тот же текст, теперь работает покрывающий индекс */
SELECT d.DepartmentName, AVG(e.Salary) AS AvgSalary, COUNT(*) AS EmployeeCount
FROM Departments d
JOIN Employees e ON d.DepartmentID = e.DepartmentID
GROUP BY d.DepartmentName
ORDER BY AvgSalary DESC;
GO 3

/* Запрос A' — избирательный предикат + проекция вместо SELECT * */
SELECT EmployeeID, LastName, Salary
FROM Employees
WHERE Salary > 75000;
GO 3
