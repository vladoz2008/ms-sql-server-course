/* =====================================================================
   ПРАКТИЧЕСКАЯ РАБОТА 3. Логика службы каршеринга электрокаров
   Файл 1 — схема и тестовые данные (выданы в задании без изменений)
   ===================================================================== */
USE master;
GO
IF DB_ID('CarSharingDB') IS NOT NULL
BEGIN
    ALTER DATABASE CarSharingDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CarSharingDB;
END
GO
CREATE DATABASE CarSharingDB;
GO
USE CarSharingDB;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE TABLE dbo.Cars (
    CarId           INT IDENTITY(1,1) PRIMARY KEY,
    VinNumber       NVARCHAR(50) NOT NULL UNIQUE,
    Model           NVARCHAR(50) NOT NULL,
    Year            INT NOT NULL,
    MaxRangeKm      INT NOT NULL,                     -- запас хода на полном заряде
    BatteryLevel    INT NOT NULL DEFAULT 100,         -- 0–100 %
    CurrentMileage  DECIMAL(10,2) NOT NULL,           -- пробег в км
    Status          NVARCHAR(20) NOT NULL DEFAULT 'Available'
        CHECK (Status IN ('Available','Rented','Maintenance','Charging','Accident')),
    LastServiceDate DATE NULL,
    NextServiceKm   DECIMAL(8,2) NOT NULL
);
GO
CREATE TABLE dbo.Drivers (
    DriverId      INT IDENTITY(1,1) PRIMARY KEY,
    FullName      NVARCHAR(100) NOT NULL,
    LicenseNumber NVARCHAR(20) NOT NULL UNIQUE,
    LicenseExpiry DATE NOT NULL,
    TotalRents    INT NOT NULL DEFAULT 0,
    TotalDistance DECIMAL(10,2) NOT NULL DEFAULT 0,
    AccidentCount INT NOT NULL DEFAULT 0,
    IsActive      BIT NOT NULL DEFAULT 1
);
GO
CREATE TABLE dbo.Customers (
    CustomerId INT IDENTITY(1,1) PRIMARY KEY,
    FullName   NVARCHAR(100) NOT NULL,
    Phone      NVARCHAR(20) NOT NULL,
    Email      NVARCHAR(100) NULL,
    City       NVARCHAR(50) NOT NULL
);
GO
CREATE TABLE dbo.Rentals (
    RentalId        INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId      INT NOT NULL,
    CarId           INT NOT NULL,
    DriverId        INT NOT NULL,
    StartAt         DATETIME NOT NULL,
    EndAt           DATETIME NULL,
    StartOdometer   DECIMAL(10,2) NOT NULL,
    EndOdometer     DECIMAL(10,2) NULL,
    DistanceCovered DECIMAL(10,2) NULL,
    BaseCost        DECIMAL(10,2) NOT NULL,
    ExtraCost       DECIMAL(10,2) NOT NULL DEFAULT 0,
    TotalCost       DECIMAL(10,2) NULL,
    Status          NVARCHAR(20) NOT NULL DEFAULT 'Active'
        CHECK (Status IN ('Active','Completed','Cancelled','Disputed')),
    CreatedAt       DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Rentals_Customer FOREIGN KEY (CustomerId) REFERENCES dbo.Customers(CustomerId),
    CONSTRAINT FK_Rentals_Car      FOREIGN KEY (CarId)      REFERENCES dbo.Cars(CarId),
    CONSTRAINT FK_Rentals_Driver   FOREIGN KEY (DriverId)   REFERENCES dbo.Drivers(DriverId)
);
GO
CREATE TABLE dbo.ChargingLogs (
    LogId             INT IDENTITY(1,1) PRIMARY KEY,
    CarId             INT NOT NULL,
    ChargingStart     DATETIME NOT NULL,
    ChargingEnd       DATETIME NULL,
    EnergyConsumedKwh DECIMAL(6,2) NULL,
    ChargeFrom        INT NULL,
    ChargeTo          INT NULL,
    Location          NVARCHAR(100) NULL,
    CONSTRAINT FK_CL_Car FOREIGN KEY (CarId) REFERENCES dbo.Cars(CarId)
);
GO
CREATE TABLE dbo.RentalStatusLog (
    LogId     INT IDENTITY(1,1) PRIMARY KEY,
    RentalId  INT NOT NULL,
    OldStatus NVARCHAR(20) NULL,
    NewStatus NVARCHAR(20) NOT NULL,
    ChangedAt DATETIME NOT NULL DEFAULT GETDATE(),
    ChangedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    CONSTRAINT FK_RSL_Rental FOREIGN KEY (RentalId) REFERENCES dbo.Rentals(RentalId)
);
GO
/* ---------------------- Тестовые данные ---------------------- */
SET NOCOUNT ON;
INSERT dbo.Cars (VinNumber, Model, Year, MaxRangeKm, BatteryLevel, CurrentMileage, Status, LastServiceDate, NextServiceKm) VALUES
 (N'WBA12345678901234', N'BMW i3',        2021, 260, 82, 15200.5, N'Available',   '2025-08-01', 16000),
 (N'WBA54321987654321', N'BMW i3',        2022, 260, 45,  9800.2, N'Available',   '2025-07-10', 10500),
 (N'VIN-TESLA-001',     N'Tesla Model 3', 2023, 528, 95,  3200.0, N'Available',   '2025-09-01',  5000),
 (N'VIN-TESLA-002',     N'Tesla Model 3', 2020, 425, 12, 41200.7, N'Charging',    '2025-08-15', 42000),
 (N'VIN-NISSAN-LEAF',   N'Nissan Leaf',   2019, 240, 70, 58000.3, N'Maintenance', '2025-06-01', 60000);

INSERT dbo.Drivers (FullName, LicenseNumber, LicenseExpiry, TotalRents, TotalDistance, AccidentCount, IsActive) VALUES
 (N'Игорь Петров',    N'DL-2024-101', '2027-12-31', 35, 1200.5, 0, 1),
 (N'Ольга Смирнова',  N'DL-2024-102', '2026-11-20', 52, 2100.0, 1, 1),
 (N'Дмитрий Волков',  N'DL-2023-103', '2025-10-10',  8,  320.2, 2, 1),
 (N'Анна Кузнецова',  N'DL-2025-104', '2028-03-05', 12,  450.0, 0, 1);

INSERT dbo.Customers (FullName, Phone, Email, City) VALUES
 (N'Сергей Иванов',  N'+7-900-111-22-33', N'sergey@example.com', N'Москва'),
 (N'Елена Морозова', N'+7-900-222-33-44', N'elena@example.com',  N'Москва'),
 (N'Максим Соколов', N'+7-900-333-44-55', NULL,                  N'Санкт-Петербург'),
 (N'Ирина Лебедева', N'+7-900-444-55-66', N'irina@example.com',  N'Казань');

INSERT dbo.Rentals (CustomerId, CarId, DriverId, StartAt, EndAt, StartOdometer, EndOdometer, DistanceCovered, BaseCost, ExtraCost, TotalCost, Status, CreatedAt) VALUES
 (1, 1, 1, '2025-09-17 09:00', '2025-09-17 14:30', 15200.5, 15245.2, 44.7, 2800.00, 0, NULL, 'Completed', '2025-09-17 08:55'),
 (2, 3, 2, '2025-09-17 11:00', '2025-09-17 13:15',  3200.0,  3285.5, 85.5, 4200.00, 0, NULL, 'Completed', '2025-09-17 10:55'),
 (3, 2, 3, '2025-09-18 08:00', NULL,                9800.2, NULL,    NULL, 1800.00, 0, NULL, 'Active',    '2025-09-18 07:55'),
 (4, 1, 4, '2025-09-18 10:30', NULL,               15245.2, NULL,    NULL, 2500.00, 0, NULL, 'Active',    '2025-09-18 10:25');

INSERT dbo.ChargingLogs (CarId, ChargingStart, ChargingEnd, EnergyConsumedKwh, ChargeFrom, ChargeTo, Location) VALUES
 (2, '2025-09-17 20:00', '2025-09-18 00:30', 32.5, 45, 98,   N'Зарядная станция ВДНХ'),
 (4, '2025-09-18 09:00', NULL,               NULL, 12, NULL, N'Подземная парковка ТЦ');
GO
PRINT N'CarSharingDB: схема и тестовые данные загружены.';
GO
