/* =====================================================================
   Задача 4. Разрешить обновлять только статус заказа
   ===================================================================== */
USE MyDB;
GO
GRANT UPDATE (Status) ON Orders TO Writer;
GO
EXECUTE AS USER = 'Writer';
UPDATE Orders SET Status='Completed' WHERE OrderID=100;
UPDATE Orders SET Total=999 WHERE OrderID=100;
REVERT;
GO
SELECT OrderID, Total, Status FROM Orders WHERE OrderID=100;
GO
