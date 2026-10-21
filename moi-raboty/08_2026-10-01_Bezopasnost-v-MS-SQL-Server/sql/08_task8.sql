/* =====================================================================
   Задача 8. Проверка отката при нарушении прав
   ===================================================================== */
USE MyDB;
GO
-- состояние ДО
SELECT OrderID, Total, Status FROM Orders WHERE OrderID=100;
GO
BEGIN TRAN;
GO
EXECUTE AS USER = 'Writer';
GO
UPDATE Orders SET Total = 9999 WHERE OrderID=100;   -- нарушение прав
GO
SELECT @@TRANCOUNT AS TranCount, USER_NAME() AS CurrentUser;
GO
REVERT;
GO
ROLLBACK;
GO
-- состояние ПОСЛЕ
SELECT @@TRANCOUNT AS TranCount;
SELECT OrderID, Total, Status FROM Orders WHERE OrderID=100;
GO
