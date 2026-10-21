/* Требование 8: прямой UPDATE в обход процедур — сценарий из задания */
USE CarSharingDB;
GO
-- Автомобиль 5 (Nissan Leaf) находится в статусе Maintenance
SELECT CarId, Model, Status FROM dbo.Cars ORDER BY CarId;
GO
-- Аренда 4 активна и ссылается на исправный автомобиль
SELECT RentalId, CarId, Status FROM dbo.Rentals WHERE RentalId = 4;
GO
-- Попытка назначить на аренду автомобиль в ремонте
UPDATE dbo.Rentals SET CarId = 5 WHERE RentalId = 4;
GO
-- Контроль: изменение отклонено, аренда по-прежнему на автомобиле 1
SELECT RentalId, CarId, Status FROM dbo.Rentals WHERE RentalId = 4;
GO
