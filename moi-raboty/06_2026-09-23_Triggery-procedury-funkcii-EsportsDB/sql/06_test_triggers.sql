/* =====================================================================
   Файл 4в — ТЕСТЫ ТРИГГЕРОВ
   ===================================================================== */
USE EsportsDB;
GO
SET NOCOUNT ON;
PRINT N'===== ТРИГГЕР 1. TR_Teams_PreventActiveDelete =====';
GO
-- Две служебные команды без связанных записей (чтобы внешние ключи не мешали)
INSERT dbo.Teams (Name, Country, FoundedDate, TotalPrizeMoney, IsActive) VALUES
 (N'Retired Legends',  N'Германия', '2017-01-01', 0, 0),   -- неактивна
 (N'Stellar Vanguard', N'Польша',   '2024-01-01', 0, 1);   -- активна
SELECT TeamId, Name, IsActive FROM dbo.Teams WHERE Name IN (N'Retired Legends', N'Stellar Vanguard');
GO
-- 1.1 Успех: удаление НЕактивной команды проходит
DELETE FROM dbo.Teams WHERE Name = N'Retired Legends';
PRINT N'OK: неактивная команда удалена, строк затронуто: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO
-- 1.2 Ошибка 50030: удаление активной команды откатывается
BEGIN TRY
    DELETE FROM dbo.Teams WHERE Name = N'Stellar Vanguard';
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
SELECT TeamId, Name, IsActive FROM dbo.Teams WHERE Name = N'Stellar Vanguard';  -- команда на месте
GO
-- 1.3 После деактивации удаление проходит
UPDATE dbo.Teams SET IsActive = 0 WHERE Name = N'Stellar Vanguard';
DELETE FROM dbo.Teams WHERE Name = N'Stellar Vanguard';
PRINT N'OK: после деактивации команда удалена.';
GO

PRINT N'===== ТРИГГЕР 2. TR_Matches_AutoStats =====';
GO
-- Новый матч показательного раунда: Phoenix Reign (2) vs Void Hunters (3)
INSERT dbo.Matches (TournamentId, Round, Team1Id, Team2Id, MatchDate, IsCompleted)
VALUES (1, 3, 2, 3, '2025-12-14', 0);
DECLARE @M INT = SCOPE_IDENTITY();
PRINT CONCAT(N'Создан матч MatchId = ', @M);
SELECT COUNT(*) AS Строк_статистики_ДО FROM dbo.PlayerMatchStats WHERE MatchId = @M;

-- 2.1 UPDATE поля, НЕ связанного с IsCompleted — триггер ничего не вставляет
UPDATE dbo.Matches SET MatchDate = '2025-12-15' WHERE MatchId = @M;
SELECT COUNT(*) AS После_UPDATE_MatchDate FROM dbo.PlayerMatchStats WHERE MatchId = @M;

-- 2.2 Перевод IsCompleted 0 -> 1: создаются заготовки для 10 игроков
UPDATE dbo.Matches SET Team1Score = 2, Team2Score = 0, WinnerId = 2, IsCompleted = 1
WHERE MatchId = @M;
SELECT COUNT(*) AS После_завершения_матча FROM dbo.PlayerMatchStats WHERE MatchId = @M;

SELECT s.PlayerId, p.Nickname, p.TeamId, s.MatchId, s.Kills, s.Deaths, s.Assists, s.IsMVP
FROM dbo.PlayerMatchStats AS s
JOIN dbo.Players AS p ON p.PlayerId = s.PlayerId
WHERE s.MatchId = @M ORDER BY p.TeamId, s.PlayerId;

-- 2.3 Повторный UPDATE IsCompleted (1 -> 1) дублей не создаёт
UPDATE dbo.Matches SET IsCompleted = 1 WHERE MatchId = @M;
SELECT COUNT(*) AS После_повторного_UPDATE FROM dbo.PlayerMatchStats WHERE MatchId = @M;
GO

PRINT N'===== ТРИГГЕР 3. TR_vw_PlayerTransfers_Update (INSTEAD OF на представлении) =====';
GO
SELECT TeamId, COUNT(*) AS Игроков FROM dbo.Players WHERE TeamId IS NOT NULL GROUP BY TeamId ORDER BY TeamId;
GO
-- 3.1 Ошибка 50040: перевод в ту же команду (Fade уже в Nexus Gaming)
BEGIN TRY
    UPDATE dbo.vw_PlayerTransfers SET TeamId = 1 WHERE PlayerId = 1;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO
-- 3.2 Ошибка 50041: перевод в неактивную команду Echo Squad (TeamId = 5)
BEGIN TRY
    UPDATE dbo.vw_PlayerTransfers SET TeamId = 5 WHERE PlayerId = 1;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO
-- 3.3 Ошибка 50042: Void Hunters (TeamId = 3) уже укомплектована пятью игроками
BEGIN TRY
    UPDATE dbo.vw_PlayerTransfers SET TeamId = 3 WHERE PlayerId = 1;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO
-- Освобождаем слот в Void Hunters: Dusk (PlayerId = 15) уходит в свободные агенты.
-- Делается напрямую по таблице, потому что перевод «в никуда» представлением не предусмотрен.
UPDATE dbo.Players SET TeamId = NULL WHERE PlayerId = 15;
SELECT COUNT(*) AS Игроков_в_VoidHunters FROM dbo.Players WHERE TeamId = 3;
GO
-- 3.4 Успех: Fade переходит из Nexus Gaming в Void Hunters
UPDATE dbo.vw_PlayerTransfers SET TeamId = 3 WHERE PlayerId = 1;
PRINT N'OK: трансфер выполнен.';
SELECT PlayerId, Nickname, TeamId, TeamName FROM dbo.vw_PlayerTransfers WHERE PlayerId = 1;
GO
-- 3.5 Ошибка 50042: Silent Storm (TeamId = 4) укомплектована
BEGIN TRY
    UPDATE dbo.vw_PlayerTransfers SET TeamId = 4 WHERE PlayerId = 1;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO
-- 3.6 Обновление прочих полей через представление игнорируется (меняется только TeamId)
UPDATE dbo.vw_PlayerTransfers SET Nickname = N'FadeAway' WHERE PlayerId = 1;
SELECT PlayerId, Nickname FROM dbo.Players WHERE PlayerId = 1;   -- ник не изменился
GO
SELECT TeamId, COUNT(*) AS Игроков FROM dbo.Players WHERE TeamId IS NOT NULL GROUP BY TeamId ORDER BY TeamId;
GO
