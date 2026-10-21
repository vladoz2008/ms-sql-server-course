/* ПР24. Шаг 3 — проблемные запросы (до оптимизации), каждый по 3 раза */
USE TrainingDB;
GO

/* Запрос A — сканирование таблицы (без индекса) */
SELECT *
FROM Employees
WHERE Salary > 50000;
GO 3

/* Запрос B — JOIN с большим объёмом данных */
SELECT e.FirstName, e.LastName, d.DepartmentName, p.ProjectName, t.HoursWorked
FROM Employees e
JOIN Departments d ON e.DepartmentID = d.DepartmentID
JOIN Timesheets t ON e.EmployeeID = t.EmployeeID
JOIN Projects p ON t.ProjectID = p.ProjectID
WHERE t.WorkDate BETWEEN '2023-01-01' AND '2023-12-31';
GO 3

/* Запрос C — агрегация по отделам */
SELECT d.DepartmentName, AVG(e.Salary) AS AvgSalary, COUNT(*) AS EmployeeCount
FROM Departments d
JOIN Employees e ON d.DepartmentID = e.DepartmentID
GROUP BY d.DepartmentName
ORDER BY AvgSalary DESC;
GO 3
