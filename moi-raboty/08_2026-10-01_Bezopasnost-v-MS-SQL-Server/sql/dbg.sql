USE MyDB;
GO
PRINT '--- 3a: INSERT как Writer (OrderID=100, уже существует)';
GO
EXECUTE AS USER = 'Writer';
GO
INSERT INTO Orders VALUES (100,1,GETDATE(),500,'Pending');
GO
PRINT '--- 3b: DELETE как Writer';
GO
DELETE FROM Orders WHERE OrderID=100;
GO
PRINT '--- 3c: SELECT как Writer';
GO
SELECT * FROM Orders WHERE OrderID=100;
GO
PRINT '--- 3d: INSERT свободного OrderID=200';
GO
INSERT INTO Orders VALUES (200,1,GETDATE(),500,'Pending');
GO
PRINT '--- 3e: DELETE OrderID=200';
GO
DELETE FROM Orders WHERE OrderID=200;
GO
PRINT '--- 4a: UPDATE Status';
GO
UPDATE Orders SET Status='Completed' WHERE OrderID=100;
GO
PRINT '--- 4b: UPDATE Total';
GO
UPDATE Orders SET Total=999 WHERE OrderID=100;
GO
REVERT;
GO
PRINT '--- контроль как dbo';
SELECT OrderID, CustomerID, Total, Status FROM Orders ORDER BY OrderID;
GO
