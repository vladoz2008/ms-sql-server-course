/* =====================================================================
   Файл 3 — тестовые вызовы (требования 1–7)
   Для каждого требования: успешный сценарий + сценарий с ошибкой
   ===================================================================== */
USE CarSharingDB;
GO
SET NOCOUNT ON;

PRINT N'===== ТРЕБОВАНИЕ 2. fn_EstimatedRangeKm =====';
GO
-- 2.1 Успех: показатель доступен прямо в SELECT, WHERE и ORDER BY
SELECT CarId, Model, MaxRangeKm, BatteryLevel, Status,
       dbo.fn_EstimatedRangeKm(MaxRangeKm, BatteryLevel) AS EstimatedRangeKm
FROM dbo.Cars
ORDER BY EstimatedRangeKm DESC;
GO
-- 2.2 Фильтрация по расчётному показателю: авто, доедущие минимум 150 км
SELECT CarId, Model, dbo.fn_EstimatedRangeKm(MaxRangeKm, BatteryLevel) AS EstimatedRangeKm
FROM dbo.Cars
WHERE dbo.fn_EstimatedRangeKm(MaxRangeKm, BatteryLevel) >= 150;
GO
-- 2.3 Граничный случай: нулевой заряд -> 0 км
SELECT dbo.fn_EstimatedRangeKm(528, 0) AS Запас_при_нулевом_заряде;
GO

PRINT N'===== ТРЕБОВАНИЕ 6. fn_DriverReliability =====';
GO
-- 6.1 Успех: рейтинг в SELECT по водителям
SELECT DriverId, FullName, TotalRents, AccidentCount,
       dbo.fn_DriverReliability(TotalRents, AccidentCount) AS ReliabilityRating
FROM dbo.Drivers
ORDER BY ReliabilityRating DESC;
GO
-- 6.2 Граничный случай: у водителя нет поездок -> 0, деления на ноль не происходит
SELECT dbo.fn_DriverReliability(0, 0) AS Рейтинг_без_поездок;
GO

PRINT N'===== ТРЕБОВАНИЕ 3. sp_CreateRental =====';
GO
-- 3.1 Успех: Tesla Model 3 (CarId = 3) свободна, заряд 95 %
DECLARE @NewId INT;
EXEC dbo.sp_CreateRental @CustomerId = 1, @CarId = 3, @DriverId = 1,
     @BaseCost = 3000.00, @NewRentalId = @NewId OUTPUT;
SELECT RentalId, CustomerId, CarId, DriverId, StartOdometer, Status FROM dbo.Rentals WHERE RentalId = @NewId;
SELECT CarId, Model, Status FROM dbo.Cars WHERE CarId = 3;
GO
-- 3.2 Ошибка 50011: Nissan Leaf (CarId = 5) в статусе Maintenance
DECLARE @NewId INT;
BEGIN TRY
    EXEC dbo.sp_CreateRental 1, 5, 1, 2000.00, @NewId OUTPUT;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO
-- 3.3 Ошибка 50015: у водителя Дмитрия Волкова лицензия истекла 10.10.2025
DECLARE @NewId INT;
BEGIN TRY
    EXEC dbo.sp_CreateRental 1, 2, 3, 2000.00, @NewId OUTPUT;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO
-- 3.4 Ошибка 50016: заряда не хватает на ожидаемый пробег
UPDATE dbo.Cars SET BatteryLevel = 25 WHERE CarId = 2;   -- 25 % > 20 %, триггер требования 5 молчит
SELECT CarId, Model, BatteryLevel, Status FROM dbo.Cars WHERE CarId = 2;
GO
DECLARE @NewId INT;
BEGIN TRY
    EXEC dbo.sp_CreateRental 1, 2, 1, 2000.00, @NewId OUTPUT;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO

PRINT N'===== ТРЕБОВАНИЕ 4. sp_CompleteRental =====';
GO
-- 4.1 Успех: закрываем аренду 4 (BMW i3, CarId = 1), пробег +50 км
SELECT CarId, BatteryLevel, CurrentMileage, Status FROM dbo.Cars WHERE CarId = 1;
SELECT DriverId, FullName, TotalRents, TotalDistance, AccidentCount FROM dbo.Drivers WHERE DriverId = 4;
GO
EXEC dbo.sp_CompleteRental @RentalId = 4, @EndOdometer = 15295.2, @ExtraCost = 350.00;
GO
SELECT RentalId, EndOdometer, DistanceCovered, BaseCost, ExtraCost, TotalCost, Status
FROM dbo.Rentals WHERE RentalId = 4;
SELECT CarId, BatteryLevel, CurrentMileage, Status FROM dbo.Cars WHERE CarId = 1;
SELECT DriverId, FullName, TotalRents, TotalDistance, AccidentCount FROM dbo.Drivers WHERE DriverId = 4;
GO
-- 4.2 Ошибка 50021: аренда уже завершена
BEGIN TRY EXEC dbo.sp_CompleteRental 4, 15400.0;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO
-- 4.3 Ошибка 50022: конечный пробег меньше начального
BEGIN TRY EXEC dbo.sp_CompleteRental 3, 9000.0;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO

PRINT N'===== ТРЕБОВАНИЕ 5. TR_Cars_AutoCharging =====';
GO
-- 5.1 Успех: длинная поездка сажает батарею ниже 20 % -> авто само уходит на зарядку
SELECT CarId, Model, BatteryLevel, Status AS СтатусДо FROM dbo.Cars WHERE CarId = 2;
GO
EXEC dbo.sp_CompleteRental @RentalId = 3, @EndOdometer = 9900.2;   -- 100 км
GO
SELECT CarId, Model, BatteryLevel, Status AS СтатусПосле FROM dbo.Cars WHERE CarId = 2;
GO
-- 5.2 Контрольный случай: заряд выше порога — триггер не вмешивается
UPDATE dbo.Cars SET BatteryLevel = 55 WHERE CarId = 1;
SELECT CarId, Model, BatteryLevel, Status FROM dbo.Cars WHERE CarId = 1;
GO

PRINT N'===== ТРЕБОВАНИЕ 1. TR_Rentals_StatusLog =====';
GO
-- 1.1 Журнал заполнялся сам: при вставке аренды и при каждой смене статуса
SELECT LogId, RentalId, ISNULL(OldStatus, N'(нет)') AS OldStatus, NewStatus, ChangedBy
FROM dbo.RentalStatusLog ORDER BY LogId;
GO
-- 1.2 Прямой UPDATE в обход процедур — запись всё равно появляется
UPDATE dbo.Rentals SET Status = N'Disputed' WHERE RentalId = 1;
SELECT TOP (1) LogId, RentalId, OldStatus, NewStatus, ChangedBy
FROM dbo.RentalStatusLog ORDER BY LogId DESC;
GO
-- 1.3 «Холостой» UPDATE (статус не изменился) журнал не засоряет
DECLARE @Before INT = (SELECT COUNT(*) FROM dbo.RentalStatusLog);
UPDATE dbo.Rentals SET Status = N'Disputed' WHERE RentalId = 1;
SELECT @Before AS Записей_до, (SELECT COUNT(*) FROM dbo.RentalStatusLog) AS Записей_после;
GO

PRINT N'===== ТРЕБОВАНИЕ 7. sp_FinishCharging =====';
GO
-- 7.1 Ошибка 50033: ChargeTo меньше ChargeFrom
BEGIN TRY EXEC dbo.sp_FinishCharging @LogId = 2, @ChargeTo = 5;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO
-- 7.2 Успех: зарядили Tesla (CarId = 4) с 12 % до 90 %
SELECT CarId, Model, BatteryLevel, Status FROM dbo.Cars WHERE CarId = 4;
GO
EXEC dbo.sp_FinishCharging @LogId = 2, @ChargeTo = 90;
GO
SELECT LogId, CarId, ChargeFrom, ChargeTo, EnergyConsumedKwh, ChargingEnd FROM dbo.ChargingLogs WHERE LogId = 2;
SELECT CarId, Model, BatteryLevel, Status FROM dbo.Cars WHERE CarId = 4;
GO
-- 7.3 Ошибка 50031: повторное закрытие той же зарядки
BEGIN TRY EXEC dbo.sp_FinishCharging 2, 100;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO
