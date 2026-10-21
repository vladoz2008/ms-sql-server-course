/* =====================================================================
   ЧАСТЬ 3. Практические задания 1–11
   БД: BookShopDB (MS SQL Server 2022)
   ===================================================================== */
USE BookShopDB;
GO

-- Для создания ФИЛЬТРОВАННОГО индекса эти опции обязаны быть ON.
-- SSMS включает их по умолчанию; в sqlcmd их нужно задать явно.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ===================================================================
   ЗАДАНИЕ 1. Индексы
   =================================================================== */

-- 1.1. Кластерный индекс на Orders по OrderDate.
--      PK_Orders объявлен NONCLUSTERED, поэтому место кластерного свободно.
CREATE CLUSTERED INDEX CIX_Orders_OrderDate
    ON dbo.Orders (OrderDate);
GO

-- 1.2. Некластерный ПОКРЫВАЮЩИЙ индекс на Books по AuthorId
--      с включёнными столбцами вывода.
CREATE NONCLUSTERED INDEX IX_Books_AuthorId_Covering
    ON dbo.Books (AuthorId)
    INCLUDE (Title, Price, StockQty);
GO

-- 1.3. Фильтрованный некластерный индекс на Orders только для 'Pending'.
--      SET ... ON должен действовать в ТОМ ЖЕ пакете, что и CREATE INDEX.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
CREATE NONCLUSTERED INDEX FIX_Orders_Pending
    ON dbo.Orders (OrderDate, CustomerId)
    WHERE Status = 'Pending';
GO

-- Контроль: какие индексы получились
SELECT i.name AS IndexName, i.type_desc, i.is_unique, i.has_filter, i.filter_definition,
       OBJECT_NAME(i.object_id) AS TableName
FROM sys.indexes i
WHERE i.object_id IN (OBJECT_ID('dbo.Orders'), OBJECT_ID('dbo.Books'))
  AND i.type > 0
ORDER BY TableName, i.name;
GO

/* ===================================================================
   ЗАДАНИЕ 2. TOP с WITH TIES — топ-3 самых дорогих книг
   =================================================================== */
SELECT TOP (3) WITH TIES
       b.BookId, b.Title, b.Price
FROM dbo.Books AS b
ORDER BY b.Price DESC;
GO

/* ===================================================================
   ЗАДАНИЕ 3. IF...ELSE + EXISTS — книги с нулевым остатком
   =================================================================== */
IF EXISTS (SELECT 1 FROM dbo.Books WHERE StockQty = 0)
BEGIN
    PRINT N'Внимание: есть книги с нулевым остатком!';
    SELECT b.BookId, b.Title, b.StockQty
    FROM dbo.Books AS b
    WHERE b.StockQty = 0;
END
ELSE
BEGIN
    PRINT N'Все книги есть в наличии';
END
GO

/* ===================================================================
   ЗАДАНИЕ 4. TRY...CATCH + THROW — вставка заказа на несуществующего клиента
   =================================================================== */
BEGIN TRY
    INSERT INTO dbo.Orders (CustomerId, OrderDate, Status)
    VALUES (999, SYSDATETIME(), 'Pending');       -- клиента 999 не существует
END TRY
BEGIN CATCH
    PRINT N'--- Ошибка перехвачена в блоке CATCH ---';
    PRINT CONCAT(N'Номер ошибки : ', ERROR_NUMBER());
    PRINT CONCAT(N'Уровень      : ', ERROR_SEVERITY());
    PRINT CONCAT(N'Состояние    : ', ERROR_STATE());
    PRINT CONCAT(N'Строка       : ', ERROR_LINE());
    PRINT CONCAT(N'Сообщение    : ', ERROR_MESSAGE());
    -- повторно выбрасываем ту же ошибку: она не «проглочена»
    THROW;
END CATCH
GO

/* ===================================================================
   ЗАДАНИЕ 5. OUTPUT при UPDATE — Pending -> Shipped
   =================================================================== */
UPDATE dbo.Orders
   SET Status = 'Shipped'
OUTPUT inserted.OrderId,
       deleted.Status   AS OldStatus,
       inserted.Status  AS NewStatus
 WHERE Status = 'Pending';
GO

/* ===================================================================
   ЗАДАНИЕ 6. Переменные и WHILE
   =================================================================== */
DECLARE @threshold INT = 10;
DECLARE @cnt       INT;

WHILE @threshold > 0
BEGIN
    SELECT @cnt = COUNT(*) FROM dbo.Books WHERE StockQty < @threshold;
    PRINT CONCAT(N'Порог: ', @threshold, N', книг меньше порога: ', @cnt);
    SET @threshold = @threshold - 1;
END
PRINT CONCAT(N'Цикл завершён, @threshold = ', @threshold);
GO

/* ===================================================================
   ЗАДАНИЕ 7. MERGE — синхронизация запасов
   =================================================================== */
CREATE TABLE #BookStockStaging
(
    BookId      INT           NULL,
    NewStockQty INT           NOT NULL,
    Title       NVARCHAR(200) NOT NULL,
    AuthorId    INT           NOT NULL,
    Price       DECIMAL(10,2) NOT NULL
);

INSERT INTO #BookStockStaging (BookId, NewStockQty, Title, AuthorId, Price) VALUES
 (3,    99, N'1984',                     2,  650.00),   -- существующая книга -> UPDATE
 (NULL, 25, N'Стажёры',                  3,  640.00);   -- новой книги нет    -> INSERT

MERGE dbo.Books AS tgt
USING #BookStockStaging AS src
   ON tgt.BookId = src.BookId
WHEN MATCHED THEN
    UPDATE SET tgt.StockQty = src.NewStockQty
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Title, AuthorId, ISBN, PublishYear, Price, StockQty, IsActive)
    VALUES (src.Title, src.AuthorId, '9785171024680', 1962, src.Price, src.NewStockQty, 1)
OUTPUT $action AS Action, inserted.BookId AS InsertedBookId, deleted.BookId AS DeletedBookId;

DROP TABLE #BookStockStaging;
GO

/* ===================================================================
   ЗАДАНИЕ 8. EXISTS vs IN — авторы, у которых заказана хотя бы одна книга
   =================================================================== */

-- Вариант 1: через EXISTS
SELECT a.AuthorId, a.LastName, a.FirstName
FROM dbo.Authors AS a
WHERE EXISTS (
        SELECT 1
        FROM dbo.Books AS b
        JOIN dbo.OrderItems AS oi ON oi.BookId = b.BookId
        WHERE b.AuthorId = a.AuthorId
      );
GO

-- Вариант 2: через IN
SELECT a.AuthorId, a.LastName, a.FirstName
FROM dbo.Authors AS a
WHERE a.AuthorId IN (
        SELECT b.AuthorId
        FROM dbo.Books AS b
        JOIN dbo.OrderItems AS oi ON oi.BookId = b.BookId
      );
GO

/* ===================================================================
   ЗАДАНИЕ 9. GO и область видимости переменной
   =================================================================== */

-- Батч 1
DECLARE @city NVARCHAR(80) = N'Москва';
SELECT c.CustomerId, c.LastName, c.FirstName, c.City
FROM dbo.Customers AS c
WHERE c.City = @city;
GO

-- Батч 2: та же переменная после GO
SELECT c.CustomerId, c.LastName, c.FirstName, c.City
FROM dbo.Customers AS c
WHERE c.City = @city;     -- Msg 137: Must declare the scalar variable "@city".
GO

/* ===================================================================
   ЗАДАНИЕ 10. Клиенты, купившие в одном заказе книги 3+ разных категорий
   =================================================================== */
SELECT  c.CustomerId,
        c.LastName + N' ' + c.FirstName      AS CustomerName,
        o.OrderId,
        COUNT(DISTINCT bc.CategoryId)        AS CategoryCount
FROM dbo.Orders        AS o
JOIN dbo.Customers     AS c  ON c.CustomerId = o.CustomerId
JOIN dbo.OrderItems    AS oi ON oi.OrderId   = o.OrderId
JOIN dbo.BookCategories AS bc ON bc.BookId   = oi.BookId
GROUP BY c.CustomerId, c.LastName, c.FirstName, o.OrderId
HAVING COUNT(DISTINCT bc.CategoryId) >= 3
ORDER BY CategoryCount DESC, o.OrderId;
GO

/* ===================================================================
   ЗАДАНИЕ 11. Index Seek / Key Lookup
   Запрос: SELECT AuthorId, Title, Price FROM Books WHERE AuthorId = 1
   =================================================================== */

-- Состояние A: только узкий некластерный индекс по AuthorId (без INCLUDE)
DROP INDEX IF EXISTS IX_Books_AuthorId_Covering ON dbo.Books;
CREATE NONCLUSTERED INDEX IX_Books_AuthorId_Narrow ON dbo.Books (AuthorId);
GO
SELECT AuthorId, Title, Price FROM dbo.Books WHERE AuthorId = 1;   -- Index Seek + Key Lookup
GO

-- Состояние B: покрывающий индекс из Задания 1
DROP INDEX IF EXISTS IX_Books_AuthorId_Narrow ON dbo.Books;
CREATE NONCLUSTERED INDEX IX_Books_AuthorId_Covering
    ON dbo.Books (AuthorId) INCLUDE (Title, Price, StockQty);
GO
SELECT AuthorId, Title, Price FROM dbo.Books WHERE AuthorId = 1;   -- только Index Seek
GO
