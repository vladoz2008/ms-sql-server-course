/* =====================================================================
   Файл 4б — ТЕСТЫ ХРАНИМЫХ ПРОЦЕДУР
   ===================================================================== */
USE EsportsDB;
GO
SET NOCOUNT ON;
PRINT N'===== ПРОЦЕДУРА 1. RegisterPlayer =====';
GO
-- 1.1 Успех: совершеннолетний игрок без команды
DECLARE @Id INT;
EXEC dbo.RegisterPlayer @Nickname = N'Raven', @RealName = N'Никита Белов',
     @Country = N'Россия', @BirthDate = '2003-02-10', @TeamId = NULL, @NewPlayerId = @Id OUTPUT;
PRINT CONCAT(N'OK: создан игрок PlayerId = ', @Id);
SELECT PlayerId, Nickname, RealName, TeamId FROM dbo.Players WHERE PlayerId = @Id;
GO
-- 1.2 Ошибка 50001: игроку меньше 16 лет
DECLARE @Id INT;
BEGIN TRY
    EXEC dbo.RegisterPlayer N'KidStar', N'Тимур Лазарев', N'Россия', '2012-05-01', NULL, @Id OUTPUT;
END TRY BEGIN CATCH
    PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE());
END CATCH
GO
-- 1.3 Ошибка 50003: команда Echo Squad (TeamId = 5) неактивна
DECLARE @Id INT;
BEGIN TRY
    EXEC dbo.RegisterPlayer N'GhostEcho', N'Пётр Гусев', N'США', '2000-01-01', 5, @Id OUTPUT;
END TRY BEGIN CATCH
    PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE());
END CATCH
GO
-- 1.4 Ошибка 50002: несуществующая команда
DECLARE @Id INT;
BEGIN TRY
    EXEC dbo.RegisterPlayer N'NoTeam', N'Иван Иванов', N'Россия', '1998-01-01', 999, @Id OUTPUT;
END TRY BEGIN CATCH
    PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE());
END CATCH
GO

PRINT N'===== ПРОЦЕДУРА 2. CompleteMatch =====';
GO
-- 2.1 Ошибка 50012: ничья недопустима
BEGIN TRY EXEC dbo.CompleteMatch @MatchId = 3, @Team1Score = 2, @Team2Score = 2;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO
-- 2.2 Ошибка 50010: матча не существует
BEGIN TRY EXEC dbo.CompleteMatch 999, 2, 1;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO
-- 2.3 Успех: финал — Nexus Gaming 3:1 Silent Storm
EXEC dbo.CompleteMatch @MatchId = 3, @Team1Score = 3, @Team2Score = 1;
GO
-- 2.4 Ошибка 50011: матч уже завершён
BEGIN TRY EXEC dbo.CompleteMatch 3, 2, 0;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO
-- 2.5 Успех: матч за 3-е место — Void Hunters 2:1 Phoenix Reign
EXEC dbo.CompleteMatch @MatchId = 4, @Team1Score = 2, @Team2Score = 1;
GO
SELECT MatchId, Round, Team1Id, Team2Id, Team1Score, Team2Score, WinnerId, IsCompleted
FROM dbo.Matches ORDER BY MatchId;
GO

PRINT N'===== ПРОЦЕДУРА 3. DistributePrizes =====';
GO
-- 3.1 Ошибка 50021: турнир ещё не завершён (Status = InProgress)
BEGIN TRY EXEC dbo.DistributePrizes @TournamentId = 1;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO
-- 3.2 Завершаем турнир и распределяем призовой фонд
UPDATE dbo.Tournaments SET Status = N'Completed' WHERE TournamentId = 1;
EXEC dbo.DistributePrizes @TournamentId = 1;
GO
-- 3.3 Ошибка 50022: повторное распределение
BEGIN TRY EXEC dbo.DistributePrizes 1;
END TRY BEGIN CATCH PRINT CONCAT(N'Ошибка ', ERROR_NUMBER(), N': ', ERROR_MESSAGE()); END CATCH
GO
