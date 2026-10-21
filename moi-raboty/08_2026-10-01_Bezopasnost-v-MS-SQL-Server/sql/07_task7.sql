/* Задача 7. Ограничить доступ к «чужим» данным */
USE MyDB;
GO
CREATE OR ALTER VIEW MyOrders AS
SELECT * FROM Orders WHERE CustomerID = 1;
GO
GRANT SELECT, UPDATE ON MyOrders TO Writer;
GO
EXECUTE AS USER = 'Writer';
SELECT * FROM MyOrders;
SELECT * FROM Orders;
REVERT;
GO
