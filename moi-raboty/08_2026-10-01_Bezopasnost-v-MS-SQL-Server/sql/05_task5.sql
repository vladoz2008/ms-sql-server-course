/* Задача 5. Ограничить доступ к зарплатам сотрудников */
USE MyDB;
GO
CREATE OR ALTER VIEW EmployeesPublic AS
SELECT EmployeeID, FullName, Department FROM Employees;
GO
GRANT SELECT ON EmployeesPublic TO Reader;
GO
EXECUTE AS USER = 'Reader';
SELECT * FROM EmployeesPublic;
SELECT * FROM Employees;
REVERT;
GO
