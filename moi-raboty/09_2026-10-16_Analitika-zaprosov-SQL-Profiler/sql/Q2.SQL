/* ПР24. Шаг 5 — индексы из методички */
USE TrainingDB;
GO
IF OBJECT_ID('dbo.Employees') IS NOT NULL AND NOT EXISTS
   (SELECT 1 FROM sys.indexes WHERE name='IX_Employees_Salary')
   CREATE INDEX IX_Employees_Salary ON Employees(Salary);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Timesheets_WorkDate')
   CREATE INDEX IX_Timesheets_WorkDate ON Timesheets(WorkDate);
GO
SELECT i.name AS IndexName, OBJECT_NAME(i.object_id) AS TableName, i.type_desc
FROM sys.indexes i
WHERE i.object_id IN (OBJECT_ID('Employees'), OBJECT_ID('Timesheets'))
  AND i.name IS NOT NULL;
GO
