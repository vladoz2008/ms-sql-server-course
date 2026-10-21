/* =====================================================================
   Файл 2 — реализация восьми бизнес-требований
   ===================================================================== */
USE CarSharingDB;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =====================================================================
   ТРЕБОВАНИЕ 1. Автоматический журнал статусов аренды
   Объект: ТРИГГЕР  TR_Rentals_StatusLog  (AFTER INSERT, UPDATE)
   ---------------------------------------------------------------------
   Пишет в RentalStatusLog каждое изменение Rentals.Status, независимо от
   того, кто его сделал: процедура, приложение или прямой UPDATE.
   При вставке аренды фиксируется переход NULL -> первичный статус.
   ===================================================================== */
CREATE OR ALTER TRIGGER dbo.TR_Rentals_StatusLog
ON dbo.Rentals
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- новая аренда: старого статуса ещё не было
    INSERT dbo.RentalStatusLog (RentalId, OldStatus, NewStatus, ChangedAt, ChangedBy)
    SELECT i.RentalId, NULL, i.Status, GETDATE(), SYSTEM_USER
    FROM inserted AS i
    WHERE NOT EXISTS (SELECT 1 FROM deleted AS d WHERE d.RentalId = i.RentalId);

    -- изменение статуса существующей аренды
    IF UPDATE(Status)
        INSERT dbo.RentalStatusLog (RentalId, OldStatus, NewStatus, ChangedAt, ChangedBy)
        SELECT i.RentalId, d.Status, i.Status, GETDATE(), SYSTEM_USER
        FROM inserted AS i
        JOIN deleted  AS d ON d.RentalId = i.RentalId
        WHERE i.Status <> d.Status;     -- «холостые» UPDATE не засоряют журнал
END
GO

/* =====================================================================
   ТРЕБОВАНИЕ 2. Примерный запас хода
   Объект: СКАЛЯРНАЯ ФУНКЦИЯ  fn_EstimatedRangeKm
   ---------------------------------------------------------------------
   Чистый расчёт без обращения к таблицам: параметры передаются из строки.
   Детерминированная и WITH SCHEMABINDING — такую функцию можно применять
   в SELECT, WHERE, ORDER BY и даже в вычисляемом столбце.
   ===================================================================== */
CREATE OR ALTER FUNCTION dbo.fn_EstimatedRangeKm
    (@MaxRangeKm INT, @BatteryLevel INT)
RETURNS DECIMAL(10,2)
WITH SCHEMABINDING
AS
BEGIN
    RETURN CAST(@MaxRangeKm AS DECIMAL(10,2)) * @BatteryLevel / 100.0;
END
GO

/* =====================================================================
   ТРЕБОВАНИЕ 6. Рейтинг надёжности водителя
   Объект: СКАЛЯРНАЯ ФУНКЦИЯ  fn_DriverReliability
   ---------------------------------------------------------------------
   ((TotalRents - AccidentCount) / TotalRents) * 100, при TotalRents = 0 -> 0.
   ===================================================================== */
CREATE OR ALTER FUNCTION dbo.fn_DriverReliability
    (@TotalRents INT, @AccidentCount INT)
RETURNS DECIMAL(5,2)
WITH SCHEMABINDING
AS
BEGIN
    RETURN CASE WHEN ISNULL(@TotalRents, 0) = 0 THEN 0.00
                ELSE CAST(@TotalRents - @AccidentCount AS DECIMAL(10,4)) * 100.0 / @TotalRents
           END;
END
GO

/* =====================================================================
   ТРЕБОВАНИЕ 8. Защита от аренды неисправного авто
   Объект: ТРИГГЕР  TR_Rentals_BlockUnavailableCar  (AFTER INSERT, UPDATE)
   ---------------------------------------------------------------------
   Гарантия на уровне БД: автомобиль в статусе Maintenance, Accident или
   Charging нельзя назначить на аренду ни процедурой, ни прямым UPDATE.
   Срабатывает только когда CarId действительно назначается или меняется.
   ===================================================================== */
CREATE OR ALTER TRIGGER dbo.TR_Rentals_BlockUnavailableCar
ON dbo.Rentals
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CarId INT, @Model NVARCHAR(50), @Status NVARCHAR(20);

    SELECT TOP (1) @CarId = c.CarId, @Model = c.Model, @Status = c.Status
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.RentalId = i.RentalId
    JOIN dbo.Cars AS c ON c.CarId = i.CarId
    WHERE (d.RentalId IS NULL OR i.CarId <> d.CarId)        -- вставка или смена авто
      AND c.Status IN (N'Maintenance', N'Accident', N'Charging');

    IF @CarId IS NOT NULL
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @msg NVARCHAR(400) =
            CONCAT(N'Автомобиль ', @CarId, N' (', @Model, N') находится в статусе ''', @Status,
                   N''' и не может быть назначен на аренду.');
        THROW 50080, @msg, 1;
    END
END
GO

/* =====================================================================
   ТРЕБОВАНИЕ 5. Авто-перевод в зарядку при низком заряде
   Объект: ТРИГГЕР  TR_Cars_AutoCharging  (AFTER UPDATE)
   ---------------------------------------------------------------------
   Как только BatteryLevel опускается ниже 20 %, автомобиль сам уходит
   в статус Charging. Машины в ремонте и после ДТП не трогаем.
   ===================================================================== */
CREATE OR ALTER TRIGGER dbo.TR_Cars_AutoCharging
ON dbo.Cars
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(BatteryLevel) RETURN;

    UPDATE c
       SET c.Status = N'Charging'
    FROM dbo.Cars AS c
    JOIN inserted AS i ON i.CarId = c.CarId
    JOIN deleted  AS d ON d.CarId = i.CarId
    WHERE i.BatteryLevel < 20
      AND d.BatteryLevel >= 20                  -- именно момент падения ниже порога
      AND c.Status NOT IN (N'Charging', N'Maintenance', N'Accident');
END
GO

/* =====================================================================
   ТРЕБОВАНИЕ 3. Оформление аренды авто
   Объект: ХРАНИМАЯ ПРОЦЕДУРА  sp_CreateRental
   ---------------------------------------------------------------------
   Валидация + несколько изменений в одной транзакции.
   ===================================================================== */
CREATE OR ALTER PROCEDURE dbo.sp_CreateRental
    @CustomerId   INT,
    @CarId        INT,
    @DriverId     INT,
    @BaseCost     DECIMAL(10,2),
    @NewRentalId  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CarStatus NVARCHAR(20), @MaxRange INT, @Battery INT, @Odometer DECIMAL(10,2);

        SELECT @CarStatus = Status, @MaxRange = MaxRangeKm,
               @Battery = BatteryLevel, @Odometer = CurrentMileage
        FROM dbo.Cars WITH (UPDLOCK)
        WHERE CarId = @CarId;

        IF @CarStatus IS NULL
            THROW 50010, N'Автомобиль не найден.', 1;

        IF @CarStatus <> N'Available'
        BEGIN
            DECLARE @m1 NVARCHAR(300) = CONCAT(N'Автомобиль недоступен: текущий статус ''', @CarStatus, N'''.');
            THROW 50011, @m1, 1;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE CustomerId = @CustomerId)
            THROW 50012, N'Клиент не найден.', 1;

        DECLARE @LicExp DATE, @IsActive BIT;
        SELECT @LicExp = LicenseExpiry, @IsActive = IsActive
        FROM dbo.Drivers WHERE DriverId = @DriverId;

        IF @LicExp IS NULL
            THROW 50013, N'Водитель не найден.', 1;

        IF @IsActive = 0
            THROW 50014, N'Водитель неактивен.', 1;

        IF @LicExp < CAST(SYSDATETIME() AS DATE)
        BEGIN
            DECLARE @m2 NVARCHAR(300) = CONCAT(N'У водителя истекла лицензия (действовала до ', @LicExp, N').');
            THROW 50015, @m2, 1;
        END

        /* Ожидаемый пробег поездки = 30 % полного запаса хода.
           Текущий запас хода считаем функцией из требования 2.        */
        DECLARE @Expected  DECIMAL(10,2) = @MaxRange * 0.3,
                @Available DECIMAL(10,2) = dbo.fn_EstimatedRangeKm(@MaxRange, @Battery);

        IF @Available < @Expected
        BEGIN
            -- В тексте THROW нельзя использовать символ процента: он воспринимается
            -- как плейсхолдер форматирования, и сообщение приходит пустым.
            DECLARE @m3 NVARCHAR(400) = CONCAT(N'Недостаточно заряда: запас хода ', @Available,
                   N' км при уровне батареи ', @Battery, N', требуется не менее ', @Expected, N' км.');
            THROW 50016, @m3, 1;
        END

        INSERT dbo.Rentals (CustomerId, CarId, DriverId, StartAt, StartOdometer, BaseCost, Status)
        VALUES (@CustomerId, @CarId, @DriverId, GETDATE(), @Odometer, @BaseCost, N'Active');

        SET @NewRentalId = SCOPE_IDENTITY();

        UPDATE dbo.Cars SET Status = N'Rented' WHERE CarId = @CarId;

        COMMIT TRANSACTION;
        PRINT CONCAT(N'OK: оформлена аренда RentalId = ', @NewRentalId,
                     N' (авто ', @CarId, N', водитель ', @DriverId, N').');
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* =====================================================================
   ТРЕБОВАНИЕ 4. Завершение аренды и расчёт стоимости
   Объект: ХРАНИМАЯ ПРОЦЕДУРА  sp_CompleteRental
   ---------------------------------------------------------------------
   Пять таблиц-участников, расчёты и проверки — всё в одной транзакции.
   Расход батареи пропорционален пройденному пути; именно он запускает
   триггер требования 5.
   ===================================================================== */
CREATE OR ALTER PROCEDURE dbo.sp_CompleteRental
    @RentalId    INT,
    @EndOdometer DECIMAL(10,2),
    @ExtraCost   DECIMAL(10,2) = 0,
    @HadAccident BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Status NVARCHAR(20), @CarId INT, @DriverId INT,
                @StartOdo DECIMAL(10,2), @BaseCost DECIMAL(10,2);

        SELECT @Status = Status, @CarId = CarId, @DriverId = DriverId,
               @StartOdo = StartOdometer, @BaseCost = BaseCost
        FROM dbo.Rentals WITH (UPDLOCK)
        WHERE RentalId = @RentalId;

        IF @Status IS NULL
            THROW 50020, N'Аренда не найдена.', 1;

        IF @Status <> N'Active'
        BEGIN
            DECLARE @m1 NVARCHAR(300) = CONCAT(N'Нельзя завершить аренду в статусе ''', @Status, N'''.');
            THROW 50021, @m1, 1;
        END

        IF @EndOdometer < @StartOdo
            THROW 50022, N'Конечный пробег меньше начального.', 1;

        DECLARE @Distance  DECIMAL(10,2) = @EndOdometer - @StartOdo,
                @TotalCost DECIMAL(10,2) = @BaseCost + @ExtraCost;

        UPDATE dbo.Rentals
           SET EndAt = GETDATE(), EndOdometer = @EndOdometer,
               DistanceCovered = @Distance, ExtraCost = @ExtraCost,
               TotalCost = @TotalCost, Status = N'Completed'   -- сработает триггер требования 1
         WHERE RentalId = @RentalId;

        /* Расход батареи: доля пройденного пути от полного запаса хода */
        DECLARE @MaxRange INT = (SELECT MaxRangeKm FROM dbo.Cars WHERE CarId = @CarId);
        DECLARE @Used INT = CASE WHEN @MaxRange > 0
                                 THEN CEILING(@Distance * 100.0 / @MaxRange) ELSE 0 END;

        UPDATE dbo.Cars
           SET CurrentMileage = @EndOdometer,
               BatteryLevel   = CASE WHEN BatteryLevel - @Used < 0 THEN 0 ELSE BatteryLevel - @Used END,
               Status         = CASE WHEN @HadAccident = 1 THEN N'Accident' ELSE N'Available' END
         WHERE CarId = @CarId;      -- сработает триггер требования 5, если заряд упал ниже 20 %

        UPDATE dbo.Drivers
           SET TotalRents    = TotalRents + 1,
               TotalDistance = TotalDistance + @Distance,
               AccidentCount = AccidentCount + CASE WHEN @HadAccident = 1 THEN 1 ELSE 0 END
         WHERE DriverId = @DriverId;

        COMMIT TRANSACTION;
        PRINT CONCAT(N'OK: аренда ', @RentalId, N' завершена. Пробег ', @Distance,
                     N' км, к оплате ', @TotalCost, N' руб., списано заряда ', @Used, N' %.');
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* =====================================================================
   ТРЕБОВАНИЕ 7. Фиксация зарядки и восстановление заряда
   Объект: ХРАНИМАЯ ПРОЦЕДУРА  sp_FinishCharging
   ---------------------------------------------------------------------
   Закрывает запись в ChargingLogs, считает потраченную энергию
   (1 % = 1 кВт·ч) и поднимает BatteryLevel автомобиля до ChargeTo.
   ===================================================================== */
CREATE OR ALTER PROCEDURE dbo.sp_FinishCharging
    @LogId    INT,
    @ChargeTo INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CarId INT, @ChargeFrom INT, @End DATETIME;

        SELECT @CarId = CarId, @ChargeFrom = ChargeFrom, @End = ChargingEnd
        FROM dbo.ChargingLogs WITH (UPDLOCK)
        WHERE LogId = @LogId;

        IF @CarId IS NULL
            THROW 50030, N'Запись о зарядке не найдена.', 1;

        IF @End IS NOT NULL
            THROW 50031, N'Эта зарядка уже закрыта.', 1;

        IF @ChargeTo NOT BETWEEN 0 AND 100
            THROW 50032, N'Уровень заряда должен быть в диапазоне от 0 до 100.', 1;

        IF @ChargeTo < ISNULL(@ChargeFrom, 0)
        BEGIN
            DECLARE @m NVARCHAR(300) = CONCAT(N'ChargeTo (', @ChargeTo, N') меньше ChargeFrom (',
                                              @ChargeFrom, N') — зарядка не может уменьшить заряд.');
            THROW 50033, @m, 1;
        END

        DECLARE @Energy DECIMAL(6,2) = @ChargeTo - ISNULL(@ChargeFrom, 0);   -- 1 % = 1 кВт·ч

        UPDATE dbo.ChargingLogs
           SET ChargingEnd = GETDATE(), ChargeTo = @ChargeTo, EnergyConsumedKwh = @Energy
         WHERE LogId = @LogId;

        UPDATE dbo.Cars
           SET BatteryLevel = @ChargeTo,
               Status = CASE WHEN Status = N'Charging' THEN N'Available' ELSE Status END
         WHERE CarId = @CarId;

        COMMIT TRANSACTION;
        PRINT CONCAT(N'OK: зарядка ', @LogId, N' закрыта. Автомобиль ', @CarId,
                     N': заряд ', @ChargeFrom, N' % -> ', @ChargeTo, N' %, израсходовано ', @Energy, N' кВт·ч.');
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
PRINT N'Созданы 8 объектов: 3 триггера, 3 процедуры, 2 функции.';
GO
