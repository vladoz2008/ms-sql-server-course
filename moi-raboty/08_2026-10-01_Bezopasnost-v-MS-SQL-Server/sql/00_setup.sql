/* =====================================================================
   Работа на уроке 8. Безопасность в SQL Server
   Файл 0 — Часть 1: база, таблицы, тестовые данные и представления
   ===================================================================== */
USE master;
GO
IF DB_ID('MyDB') IS NOT NULL
BEGIN
    ALTER DATABASE MyDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MyDB;
END
GO
CREATE DATABASE MyDB;
GO
USE MyDB;
GO

-- 1. Таблица Students (задачи 1 и 2)
CREATE TABLE Students (
    StudentID INT PRIMARY KEY,
    FullName NVARCHAR(100),
    Age INT,
    GroupID INT
);
GO
INSERT INTO Students VALUES
(1, N'Иванов Иван', 20, 1),
(2, N'Петров Петр', 21, 1),
(3, N'Сидоров Сидор', 22, 2),
(4, N'Кузнецова Анна', 19, 2);
GO

-- 2. Таблица Groups (задачи 1 и 2 через GroupID в Students)
CREATE TABLE Groups (
    GroupID INT PRIMARY KEY,
    GroupName NVARCHAR(50)
);
GO
INSERT INTO Groups VALUES (1, N'Группа А'), (2, N'Группа Б');
GO

-- 3. Таблица Orders (задачи 3, 4, 7, 8)
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATETIME,
    Total DECIMAL(10,2),
    Status NVARCHAR(20)
);
GO
INSERT INTO Orders VALUES
(100, 1, '2025-08-01', 500.00, 'Pending'),
(101, 2, '2025-08-02', 300.00, 'Pending'),
(102, 1, '2025-08-03', 700.00, 'Completed');
GO

-- 4. Таблица Employees (задача 5)
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY,
    FullName NVARCHAR(100),
    Department NVARCHAR(50),
    Salary DECIMAL(10,2)
);
GO
INSERT INTO Employees VALUES
(1, N'Иванов И.И.', N'Отдел продаж', 50000),
(2, N'Петров П.П.', N'Бухгалтерия', 45000),
(3, N'Сидоров С.С.', N'IT', 60000);
GO

-- 5. Представления для ограничения доступа (задачи 2, 5, 7)
CREATE VIEW StudentsPublic AS
SELECT FullName, GroupID FROM Students;
GO
CREATE VIEW EmployeesPublic AS
SELECT EmployeeID, FullName, Department FROM Employees;
GO
CREATE VIEW MyOrders AS
SELECT * FROM Orders WHERE CustomerID = 1;
GO
PRINT N'MyDB: таблицы, данные и представления созданы.';
GO
