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
