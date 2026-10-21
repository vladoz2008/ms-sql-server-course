USE TrainingDB;
CREATE INDEX IX_Employees_Dept_Salary ON Employees(DepartmentID) INCLUDE (Salary);
CREATE INDEX IX_Employees_Salary_Covering ON Employees(Salary) INCLUDE (LastName);
GO
