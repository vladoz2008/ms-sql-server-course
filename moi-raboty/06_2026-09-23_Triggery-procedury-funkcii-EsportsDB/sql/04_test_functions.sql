/* =====================================================================
   Файл 4а — ТЕСТЫ ФУНКЦИЙ (выполняются на исходных данных)
   ===================================================================== */
USE EsportsDB;
GO
SET NOCOUNT ON;
PRINT N'===== ФУНКЦИЯ 1. GetPlayerKDA =====';
GO
-- 1.1 Прямой вызов для одного игрока (Fade, PlayerId = 1)
SELECT dbo.GetPlayerKDA(1) AS KDA_Fade;
GO
-- 1.2 Использование в запросе: все игроки команды 1 (Nexus Gaming)
SELECT p.PlayerId, p.Nickname, p.RealName,
       dbo.GetPlayerKDA(p.PlayerId) AS KDA
FROM dbo.Players AS p
WHERE p.TeamId = 1
ORDER BY KDA DESC;
GO
-- 1.3 Игрок без матчей -> NULL (Frostbite, PlayerId = 11)
SELECT p.Nickname, dbo.GetPlayerKDA(p.PlayerId) AS KDA_ДолженБытьNULL
FROM dbo.Players AS p WHERE p.PlayerId = 11;
GO

PRINT N'===== ФУНКЦИЯ 2. GetTeamMatchHistory =====';
GO
-- 2.1 Все матчи команды 4 (Silent Storm)
SELECT * FROM dbo.GetTeamMatchHistory(4, DEFAULT);
GO
-- 2.2 Только 1 последний матч команды 4
SELECT * FROM dbo.GetTeamMatchHistory(4, 1);
GO
-- 2.3 Команда 3 (Void Hunters) — проверяем разворот счёта:
--     в матче 1 она была Team2 и проиграла 0:2
SELECT * FROM dbo.GetTeamMatchHistory(3, NULL);
GO

PRINT N'===== ФУНКЦИЯ 3. GetTeamPowerRating =====';
GO
-- 3.1 Прямой вызов
SELECT dbo.GetTeamPowerRating(4) AS Rating_SilentStorm;
GO
-- 3.2 Рейтинг всех активных команд по убыванию
SELECT t.TeamId, t.Name, t.Country, t.TotalPrizeMoney,
       dbo.GetTeamPowerRating(t.TeamId) AS PowerRating
FROM dbo.Teams AS t
WHERE t.IsActive = 1
ORDER BY PowerRating DESC;
GO
-- 3.3 Подтверждение SCHEMABINDING
SELECT o.name, OBJECTPROPERTY(o.object_id, 'IsSchemaBound') AS IsSchemaBound
FROM sys.objects AS o WHERE o.name = 'GetTeamPowerRating';
GO
