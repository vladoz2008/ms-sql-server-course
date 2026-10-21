USE TrainingDB;
DECLARE @s NVARCHAR(MAX)=N'';
SELECT @s = @s + 'DROP INDEX ' + QUOTENAME(i.name) + ' ON ' + QUOTENAME(OBJECT_NAME(i.object_id)) + ';'
FROM sys.indexes i WHERE i.name IS NOT NULL AND i.type_desc='NONCLUSTERED'
  AND i.object_id IN (OBJECT_ID('Employees'),OBJECT_ID('Timesheets'),OBJECT_ID('Departments'),OBJECT_ID('Projects'));
IF @s <> '' EXEC sp_executesql @s;
SELECT name FROM sys.indexes WHERE object_id=OBJECT_ID('Employees');
