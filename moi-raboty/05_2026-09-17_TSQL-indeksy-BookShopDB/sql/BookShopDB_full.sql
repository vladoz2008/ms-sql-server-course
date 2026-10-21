/* =====================================================================
   ПРАКТИЧЕСКАЯ РАБОТА: T-SQL — управляющие конструкции, индексы, нормализация
   ЧАСТЬ 1. Проектирование схемы БД книжного интернет-магазина (3NF)
   Автор: Улзутуев Тимофей
   ===================================================================== */

USE master;
GO

IF DB_ID('BookShopDB') IS NOT NULL
BEGIN
    ALTER DATABASE BookShopDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BookShopDB;
END
GO

CREATE DATABASE BookShopDB;
GO

USE BookShopDB;
GO

/* ---------- 1. Authors — авторы ---------- */
CREATE TABLE dbo.Authors
(
    AuthorId     INT           IDENTITY(1,1) NOT NULL,
    LastName     NVARCHAR(60)  NOT NULL,
    FirstName    NVARCHAR(60)  NOT NULL,
    BirthYear    SMALLINT      NULL,
    Country      NVARCHAR(60)  NULL,
    CONSTRAINT PK_Authors PRIMARY KEY (AuthorId),
    CONSTRAINT UQ_Authors_FullName UNIQUE (LastName, FirstName, BirthYear),
    CONSTRAINT CK_Authors_BirthYear CHECK (BirthYear IS NULL OR BirthYear BETWEEN 1200 AND 2100)
);
GO

/* ---------- 2. Categories — категории (жанры) ---------- */
CREATE TABLE dbo.Categories
(
    CategoryId   INT           IDENTITY(1,1) NOT NULL,
    Title        NVARCHAR(80)  NOT NULL,
    Description  NVARCHAR(300) NULL,
    CONSTRAINT PK_Categories PRIMARY KEY (CategoryId),
    CONSTRAINT UQ_Categories_Title UNIQUE (Title)
);
GO

/* ---------- 3. Books — книги ---------- */
CREATE TABLE dbo.Books
(
    BookId       INT            IDENTITY(1,1) NOT NULL,
    Title        NVARCHAR(200)  NOT NULL,
    AuthorId     INT            NOT NULL,
    ISBN         CHAR(13)       NOT NULL,
    PublishYear  SMALLINT       NOT NULL,
    Price        DECIMAL(10,2)  NOT NULL,
    StockQty     INT            NOT NULL CONSTRAINT DF_Books_StockQty DEFAULT (0),
    IsActive     BIT            NOT NULL CONSTRAINT DF_Books_IsActive DEFAULT (1),
    CONSTRAINT PK_Books PRIMARY KEY (BookId),
    CONSTRAINT FK_Books_Authors FOREIGN KEY (AuthorId)
        REFERENCES dbo.Authors (AuthorId) ON UPDATE CASCADE,
    CONSTRAINT UQ_Books_ISBN   UNIQUE (ISBN),
    CONSTRAINT CK_Books_Price  CHECK (Price > 0),
    CONSTRAINT CK_Books_Stock  CHECK (StockQty >= 0),
    CONSTRAINT CK_Books_Year   CHECK (PublishYear BETWEEN 1450 AND 2100),
    CONSTRAINT CK_Books_ISBN   CHECK (ISBN NOT LIKE '%[^0-9]%')
);
GO

/* ---------- 4. BookCategories — связь «многие-ко-многим» ---------- */
CREATE TABLE dbo.BookCategories
(
    BookId      INT NOT NULL,
    CategoryId  INT NOT NULL,
    CONSTRAINT PK_BookCategories PRIMARY KEY (BookId, CategoryId),
    CONSTRAINT FK_BC_Books      FOREIGN KEY (BookId)
        REFERENCES dbo.Books (BookId) ON DELETE CASCADE,
    CONSTRAINT FK_BC_Categories FOREIGN KEY (CategoryId)
        REFERENCES dbo.Categories (CategoryId) ON DELETE CASCADE
);
GO

/* ---------- 5. Customers — клиенты ---------- */
CREATE TABLE dbo.Customers
(
    CustomerId   INT            IDENTITY(1,1) NOT NULL,
    LastName     NVARCHAR(60)   NOT NULL,
    FirstName    NVARCHAR(60)   NOT NULL,
    Email        NVARCHAR(120)  NOT NULL,
    Phone        VARCHAR(20)    NULL,
    City         NVARCHAR(80)   NOT NULL,
    RegisteredAt DATE           NOT NULL CONSTRAINT DF_Customers_Reg DEFAULT (CAST(SYSDATETIME() AS DATE)),
    CONSTRAINT PK_Customers PRIMARY KEY (CustomerId),
    CONSTRAINT UQ_Customers_Email UNIQUE (Email),
    CONSTRAINT CK_Customers_Email CHECK (Email LIKE '%_@_%._%')
);
GO

/* ---------- 6. Orders — заказы ---------- */
CREATE TABLE dbo.Orders
(
    OrderId     INT          IDENTITY(1,1) NOT NULL,
    CustomerId  INT          NOT NULL,
    OrderDate   DATETIME2(0) NOT NULL CONSTRAINT DF_Orders_Date DEFAULT (SYSDATETIME()),
    Status      VARCHAR(20)  NOT NULL CONSTRAINT DF_Orders_Status DEFAULT ('Pending'),
    -- PK объявлен NONCLUSTERED: кластерный индекс строится по OrderDate (Задание 1)
    CONSTRAINT PK_Orders PRIMARY KEY NONCLUSTERED (OrderId),
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerId)
        REFERENCES dbo.Customers (CustomerId),
    CONSTRAINT CK_Orders_Status CHECK (Status IN ('Pending', 'Paid', 'Shipped', 'Delivered', 'Cancelled'))
);
GO

/* ---------- 7. OrderItems — позиции заказа ---------- */
CREATE TABLE dbo.OrderItems
(
    OrderItemId INT           IDENTITY(1,1) NOT NULL,
    OrderId     INT           NOT NULL,
    BookId      INT           NOT NULL,
    Quantity    INT           NOT NULL,
    UnitPrice   DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_OrderItems PRIMARY KEY (OrderItemId),
    CONSTRAINT FK_OI_Orders FOREIGN KEY (OrderId)
        REFERENCES dbo.Orders (OrderId) ON DELETE CASCADE,
    CONSTRAINT FK_OI_Books  FOREIGN KEY (BookId)
        REFERENCES dbo.Books (BookId),
    CONSTRAINT UQ_OI_Order_Book UNIQUE (OrderId, BookId),
    CONSTRAINT CK_OI_Quantity  CHECK (Quantity > 0),
    CONSTRAINT CK_OI_UnitPrice CHECK (UnitPrice > 0)
);
GO
PRINT N'Схема BookShopDB создана: 7 таблиц.';
GO
/* =====================================================================
   ЧАСТЬ 2. Заполнение таблиц тестовыми данными
   ===================================================================== */
USE BookShopDB;
GO

/* ---------- Авторы (5) ---------- */
INSERT INTO dbo.Authors (LastName, FirstName, BirthYear, Country) VALUES
 (N'Толстой',    N'Лев',     1828, N'Россия'),
 (N'Оруэлл',     N'Джордж',  1903, N'Великобритания'),
 (N'Стругацкий', N'Аркадий', 1925, N'СССР'),
 (N'Кнут',       N'Дональд', 1938, N'США'),
 (N'Ремарк',     N'Эрих',    1898, N'Германия');
GO

/* ---------- Категории (5) ---------- */
INSERT INTO dbo.Categories (Title, Description) VALUES
 (N'Классическая литература', N'Произведения, вошедшие в мировой литературный канон'),
 (N'Фантастика',              N'Научная и социальная фантастика'),
 (N'Антиутопия',              N'Романы о тоталитарных и дистопических обществах'),
 (N'Программирование',        N'Техническая литература для разработчиков'),
 (N'Историческая проза',      N'Художественные произведения на историческом материале');
GO

/* ---------- Книги (8) ---------- */
INSERT INTO dbo.Books (Title, AuthorId, ISBN, PublishYear, Price, StockQty, IsActive) VALUES
 (N'Война и мир',                        1, '9785170123456', 1869, 1290.00, 12, 1),
 (N'Анна Каренина',                      1, '9785170223457', 1878,  890.50, 20, 1),
 (N'1984',                               2, '9785170323458', 1949,  650.00, 35, 1),
 (N'Скотный двор',                       2, '9785170423459', 1945,  420.00,  0, 1),
 (N'Пикник на обочине',                  3, '9785170523460', 1972,  570.00, 15, 1),
 (N'Трудно быть богом',                  3, '9785170623461', 1964,  610.00,  8, 1),
 (N'Искусство программирования. Том 1',  4, '9785170723462', 1968, 3450.00,  5, 1),
 (N'На Западном фронте без перемен',     5, '9785170823463', 1929,  730.00, 18, 0),
 (N'Три товарища',                       5, '9785170923464', 1936,  890.50, 11, 1);
GO

/* ---------- Связь книга — категория (M:N, у части книг по 2 категории) ---------- */
INSERT INTO dbo.BookCategories (BookId, CategoryId) VALUES
 (1,1),(1,5),      -- Война и мир: классика + историческая проза
 (2,1),            -- Анна Каренина: классика
 (3,3),(3,2),      -- 1984: антиутопия + фантастика
 (4,3),(4,1),      -- Скотный двор: антиутопия + классика
 (5,2),            -- Пикник на обочине: фантастика
 (6,2),            -- Трудно быть богом: фантастика
 (7,4),            -- Кнут: программирование
 (8,1),(8,5),      -- Ремарк: классика + историческая проза
 (9,1);            -- Три товарища: классика (цена совпадает с «Анной Карениной» — для TOP ... WITH TIES)
GO

/* ---------- Клиенты (6) ---------- */
INSERT INTO dbo.Customers (LastName, FirstName, Email, Phone, City, RegisteredAt) VALUES
 (N'Иванов',   N'Пётр',    N'ivanov.p@mail.ru',    '+79001112233', N'Москва',          '2025-02-14'),
 (N'Петрова',  N'Анна',    N'petrova.a@gmail.com', '+79162223344', N'Санкт-Петербург', '2025-04-03'),
 (N'Сидоров',  N'Игорь',   N'sidorov.i@yandex.ru', '+79263334455', N'Новосибирск',     '2025-06-21'),
 (N'Кузнецова',N'Мария',   N'kuznetsova.m@mail.ru','+79374445566', N'Казань',          '2025-09-10'),
 (N'Волков',   N'Дмитрий', N'volkov.d@outlook.com', NULL,          N'Екатеринбург',    '2026-01-18'),
 (N'Зайцева',  N'Ольга',   N'zaytseva.o@gmail.com','+79055556677', N'Москва',          '2026-03-02');
GO

/* ---------- Заказы (10) ---------- */
INSERT INTO dbo.Orders (CustomerId, OrderDate, Status) VALUES
 (1, '2026-01-12 10:24:00', 'Delivered'),
 (1, '2026-02-03 18:47:00', 'Delivered'),
 (2, '2026-02-15 09:10:00', 'Shipped'),
 (3, '2026-03-01 12:35:00', 'Paid'),
 (2, '2026-03-19 20:05:00', 'Delivered'),
 (4, '2026-04-07 14:52:00', 'Cancelled'),
 (5, '2026-05-22 11:03:00', 'Pending'),
 (1, '2026-06-30 16:18:00', 'Pending'),
 (3, '2026-07-14 08:40:00', 'Delivered'),
 (6, '2026-08-25 19:26:00', 'Pending');
GO

/* ---------- Позиции заказов ----------
   UnitPrice хранится отдельно намеренно: это цена на момент покупки,
   она не выводится из Books.Price (цена может измениться позже).      */
INSERT INTO dbo.OrderItems (OrderId, BookId, Quantity, UnitPrice) VALUES
 (1, 1, 1, 1290.00), (1, 3, 2,  650.00), (1, 5, 1,  570.00),   -- 3 книги
 (2, 7, 1, 3450.00),
 (3, 2, 1,  890.50), (3, 8, 3,  730.00),                        -- 2 книги
 (4, 3, 1,  650.00), (4, 4, 1,  420.00), (4, 6, 2,  610.00),    -- 3 книги
 (5, 1, 2, 1250.00),                                            -- цена ниже текущей
 (6, 5, 1,  570.00), (6, 6, 1,  610.00),
 (7, 7, 2, 3450.00), (7, 3, 4,  650.00),
 (8, 2, 1,  890.50),
 (9, 8, 1,  700.00), (9, 1, 1, 1290.00), (9, 2, 2,  890.50),    -- 3 книги
 (10, 4, 5,  420.00), (10, 9, 1, 890.50);                                           -- большое количество
GO
PRINT N'Данные загружены.';
GO

/* ---------- Контроль согласованности ---------- */
SELECT 'Authors' AS TableName, COUNT(*) AS Rows FROM dbo.Authors
UNION ALL SELECT 'Categories',     COUNT(*) FROM dbo.Categories
UNION ALL SELECT 'Books',          COUNT(*) FROM dbo.Books
UNION ALL SELECT 'BookCategories', COUNT(*) FROM dbo.BookCategories
UNION ALL SELECT 'Customers',      COUNT(*) FROM dbo.Customers
UNION ALL SELECT 'Orders',         COUNT(*) FROM dbo.Orders
UNION ALL SELECT 'OrderItems',     COUNT(*) FROM dbo.OrderItems;
GO
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
