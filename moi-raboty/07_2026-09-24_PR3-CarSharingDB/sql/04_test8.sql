/* =====================================================================
   Файл 4 — тест требования 8 (TR_Rentals_BlockUnavailableCar)
   ===================================================================== */
USE CarSharingDB;
GO
SET NOCOUNT ON;
-- Состояние автомобилей: CarId = 5 находится в ремонте
SELECT CarId, Model, Status FROM dbo.Cars ORDER BY CarId;
GO
-- 8.1 ОШИБКА: прямой UPDATE в обход всех процедур (сценарий из задания)
UPDATE dbo.Rentals SET CarId = 5 WHERE RentalId = 4;
GO
-- 8.2 ОШИБКА: попытка вставить аренду напрямую, минуя sp_CreateRental
INSERT dbo.Rentals (CustomerId, CarId, DriverId, StartAt, StartOdometer, BaseCost, Status)
VALUES (1, 5, 1, GETDATE(), 58000.3, 1500.00, N'Active');
GO
-- 8.3 УСПЕХ: назначение исправного автомобиля проходит без препятствий
UPDATE dbo.Rentals SET CarId = 1 WHERE RentalId = 2;
PRINT N'OK: исправный автомобиль назначен, строк затронуто: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO
-- Контроль: аренда 4 по-прежнему ссылается на исходный автомобиль
SELECT RentalId, CarId, Status FROM dbo.Rentals WHERE RentalId IN (2, 4) ORDER BY RentalId;
GO
