/* =====================================================================
   Задача 3. Запрет удаления заказов
   Writer может добавлять заказы, но не удалять их.
   ===================================================================== */
USE MyDB;
GO
GRANT INSERT ON Orders TO Writer;
DENY  DELETE ON Orders TO Writer;
-- Правка 1: WHERE-условие читает столбец OrderID, а чтение требует права SELECT
-- на этот столбец. Без этой строки DELETE падает с ошибкой SELECT, а не DELETE.
GRANT SELECT (OrderID) ON Orders TO Writer;
GO
EXECUTE AS USER = 'Writer';
-- Правка 2: в тестовых данных заказ 100 уже существует, поэтому вставляем 200
INSERT INTO Orders VALUES (200,1,GETDATE(),500,'Pending');
DELETE FROM Orders WHERE OrderID=200;
REVERT;
GO
-- Правка 3: контрольный SELECT выполняется уже от имени dbo
SELECT * FROM Orders WHERE OrderID=200;
GO
