/* =====================================================================
   Файл 3 из 4 — 9 программных объектов
   3 хранимые процедуры, 3 пользовательские функции, 3 триггера
   ===================================================================== */
USE EsportsDB;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =====================================================================
   ПРОЦЕДУРА 1 (простая). RegisterPlayer — регистрация игрока
   ---------------------------------------------------------------------
   Проверки: возраст >= 16 лет на дату регистрации;
             если передан TeamId — команда должна существовать и быть активной.
   Возвращает новый PlayerId через OUTPUT-параметр.
   ===================================================================== */
CREATE OR ALTER PROCEDURE dbo.RegisterPlayer
    @Nickname     NVARCHAR(50),
    @RealName     NVARCHAR(100),
    @Country      NVARCHAR(50),
    @BirthDate    DATE,
    @TeamId       INT = NULL,          -- необязательный: игрок может быть без команды
    @NewPlayerId  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    /* --- 1. Возраст: полных лет на сегодня --- */
    DECLARE @Age INT =
        DATEDIFF(YEAR, @BirthDate, CAST(SYSDATETIME() AS DATE))
        - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, @BirthDate, CAST(SYSDATETIME() AS DATE)), @BirthDate)
                    > CAST(SYSDATETIME() AS DATE)
               THEN 1 ELSE 0 END;

    IF @Age < 16
        THROW 50001, N'Игрок моложе 16 лет — регистрация запрещена.', 1;

    /* --- 2. Команда (только если она указана) --- */
    IF @TeamId IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.Teams WHERE TeamId = @TeamId)
            THROW 50002, N'Команда с указанным TeamId не найдена.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Teams WHERE TeamId = @TeamId AND IsActive = 1)
            THROW 50003, N'Команда неактивна — регистрация в неё невозможна.', 1;
    END

    /* --- 3. Вставка и возврат идентификатора --- */
    INSERT dbo.Players (Nickname, RealName, Country, BirthDate, TeamId)
    VALUES (@Nickname, @RealName, @Country, @BirthDate, @TeamId);

    SET @NewPlayerId = SCOPE_IDENTITY();   -- SCOPE_IDENTITY, а не @@IDENTITY:
                                           -- не поймает значение из возможного триггера
END
GO

/* =====================================================================
   ПРОЦЕДУРА 2 (средняя). CompleteMatch — завершение матча
   ---------------------------------------------------------------------
   Проверки: матч существует и ещё не завершён; ничья недопустима.
   Транзакция + SET XACT_ABORT ON + TRY...CATCH + THROW.
   ===================================================================== */
CREATE OR ALTER PROCEDURE dbo.CompleteMatch
    @MatchId    INT,
    @Team1Score INT,
    @Team2Score INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;      -- любая ошибка гарантированно откатывает транзакцию

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Team1Id INT, @Team2Id INT, @IsCompleted BIT;

        SELECT @Team1Id = Team1Id, @Team2Id = Team2Id, @IsCompleted = IsCompleted
        FROM dbo.Matches WITH (UPDLOCK)   -- блокируем строку до конца транзакции
        WHERE MatchId = @MatchId;

        IF @Team1Id IS NULL
            THROW 50010, N'Матч с указанным MatchId не найден.', 1;

        IF @IsCompleted = 1
            THROW 50011, N'Матч уже завершён.', 1;

        IF @Team1Score = @Team2Score
            THROW 50012, N'Ничья недопустима.', 1;

        DECLARE @WinnerId INT = CASE WHEN @Team1Score > @Team2Score THEN @Team1Id ELSE @Team2Id END;

        UPDATE dbo.Matches
           SET Team1Score  = @Team1Score,
               Team2Score  = @Team2Score,
               WinnerId    = @WinnerId,
               IsCompleted = 1            -- здесь сработает триггер TR_Matches_AutoStats
         WHERE MatchId = @MatchId;

        COMMIT TRANSACTION;

        PRINT CONCAT(N'Матч ', @MatchId, N' завершён. Победитель: TeamId = ', @WinnerId);
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;                            -- пробрасываем исходную ошибку вызывающему коду
    END CATCH
END
GO

/* =====================================================================
   ПРОЦЕДУРА 3 (сложная). DistributePrizes — распределение призового фонда
   ---------------------------------------------------------------------
   50 % / 30 % / 20 % за 1-е, 2-е и 3-е место.
   Финал — матч максимального раунда, обе команды которого выиграли
   предыдущий раунд; матч за 3-е место — матч того же раунда между
   проигравшими. Всё в одной транзакции.
   ===================================================================== */
CREATE OR ALTER PROCEDURE dbo.DistributePrizes
    @TournamentId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Status NVARCHAR(20), @PrizePool DECIMAL(12,2);

        SELECT @Status = Status, @PrizePool = PrizePool
        FROM dbo.Tournaments WITH (UPDLOCK)
        WHERE TournamentId = @TournamentId;

        IF @Status IS NULL
            THROW 50020, N'Турнир с указанным TournamentId не найден.', 1;

        IF @Status <> N'Completed'
            THROW 50021, N'Призы можно распределять только по завершённому турниру (Status = Completed).', 1;

        IF EXISTS (SELECT 1 FROM dbo.PrizeDistributions WHERE TournamentId = @TournamentId)
            THROW 50022, N'Призы уже распределены.', 1;

        /* --- максимальный раунд среди завершённых матчей --- */
        DECLARE @MaxRound INT =
            (SELECT MAX(Round) FROM dbo.Matches
              WHERE TournamentId = @TournamentId AND IsCompleted = 1);

        IF @MaxRound IS NULL
            THROW 50023, N'У турнира нет завершённых матчей.', 1;

        /* --- финал: обе команды пришли из предыдущего раунда победителями.
               Если в последнем раунде всего один матч — он и есть финал.   --- */
        DECLARE @FinalId INT, @ThirdPlaceId INT;

        SELECT TOP (1) @FinalId = m.MatchId
        FROM dbo.Matches AS m
        WHERE m.TournamentId = @TournamentId
          AND m.Round = @MaxRound
          AND m.IsCompleted = 1
        ORDER BY
            CASE WHEN EXISTS (SELECT 1 FROM dbo.Matches p
                               WHERE p.TournamentId = @TournamentId
                                 AND p.Round = @MaxRound - 1
                                 AND p.WinnerId = m.Team1Id)
                  AND EXISTS (SELECT 1 FROM dbo.Matches p
                               WHERE p.TournamentId = @TournamentId
                                 AND p.Round = @MaxRound - 1
                                 AND p.WinnerId = m.Team2Id)
                 THEN 0 ELSE 1 END,      -- сначала матч между победителями
            m.MatchId;

        /* --- матч за 3-е место: другой матч того же раунда --- */
        SELECT TOP (1) @ThirdPlaceId = MatchId
        FROM dbo.Matches
        WHERE TournamentId = @TournamentId
          AND Round = @MaxRound
          AND IsCompleted = 1
          AND MatchId <> @FinalId
        ORDER BY MatchId;

        /* --- призёры --- */
        DECLARE @First INT, @Second INT, @Third INT;

        SELECT @First  = WinnerId,
               @Second = CASE WHEN WinnerId = Team1Id THEN Team2Id ELSE Team1Id END
        FROM dbo.Matches WHERE MatchId = @FinalId;

        SELECT @Third = WinnerId FROM dbo.Matches WHERE MatchId = @ThirdPlaceId;

        /* --- суммы: 50 / 30 / 20 процентов --- */
        DECLARE @Prizes TABLE (TeamId INT, Placement INT, Amount DECIMAL(12,2));

        INSERT @Prizes (TeamId, Placement, Amount)
        VALUES (@First, 1, @PrizePool * 0.50),
               (@Second, 2, @PrizePool * 0.30);

        IF @Third IS NOT NULL
            INSERT @Prizes (TeamId, Placement, Amount) VALUES (@Third, 3, @PrizePool * 0.20);

        INSERT dbo.PrizeDistributions (TournamentId, TeamId, Placement, Amount)
        SELECT @TournamentId, TeamId, Placement, Amount FROM @Prizes;

        UPDATE t
           SET t.TotalPrizeMoney = t.TotalPrizeMoney + p.Amount
        FROM dbo.Teams AS t
        JOIN @Prizes  AS p ON p.TeamId = t.TeamId;

        COMMIT TRANSACTION;

        PRINT CONCAT(N'Призовой фонд турнира ', @TournamentId, N' распределён (', @PrizePool, N').');
        SELECT pd.Placement, t.Name AS TeamName, pd.Amount, t.TotalPrizeMoney
        FROM dbo.PrizeDistributions AS pd
        JOIN dbo.Teams AS t ON t.TeamId = pd.TeamId
        WHERE pd.TournamentId = @TournamentId
        ORDER BY pd.Placement;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* =====================================================================
   ФУНКЦИЯ 1 (простая). GetPlayerKDA — средний KDA игрока
   ---------------------------------------------------------------------
   KDA одного матча = (Kills + Assists) / Deaths, при Deaths = 0 берём 1.
   Возвращается СРЕДНЕЕ по всем матчам игрока; нет матчей — NULL.
   ===================================================================== */
CREATE OR ALTER FUNCTION dbo.GetPlayerKDA (@PlayerId INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Kda DECIMAL(10,2);

    SELECT @Kda = AVG( (CAST(s.Kills AS DECIMAL(10,2)) + s.Assists)
                       / CASE WHEN s.Deaths = 0 THEN 1 ELSE s.Deaths END )
    FROM dbo.PlayerMatchStats AS s
    WHERE s.PlayerId = @PlayerId;

    RETURN @Kda;          -- если строк нет, AVG вернёт NULL — как и требуется
END
GO

/* =====================================================================
   ФУНКЦИЯ 2 (средняя). GetTeamMatchHistory — история матчей команды
   ---------------------------------------------------------------------
   Inline TVF. @GamesBack = NULL -> все матчи, иначе N последних.
   Команда может быть как Team1, так и Team2 — счёт разворачивается.
   ===================================================================== */
CREATE OR ALTER FUNCTION dbo.GetTeamMatchHistory (@TeamId INT, @GamesBack INT = NULL)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (ISNULL(@GamesBack, 2147483647))
           m.MatchId,
           m.Round,
           opp.Name AS OpponentName,
           CASE WHEN m.Team1Id = @TeamId THEN m.Team1Score ELSE m.Team2Score END AS TeamScore,
           CASE WHEN m.Team1Id = @TeamId THEN m.Team2Score ELSE m.Team1Score END AS OpponentScore,
           CASE WHEN m.IsCompleted = 0     THEN N'Pending'
                WHEN m.WinnerId  = @TeamId THEN N'Win'
                ELSE N'Loss' END AS Result,
           m.MatchDate
    FROM dbo.Matches AS m
    JOIN dbo.Teams   AS opp
      ON opp.TeamId = CASE WHEN m.Team1Id = @TeamId THEN m.Team2Id ELSE m.Team1Id END
    WHERE m.Team1Id = @TeamId OR m.Team2Id = @TeamId
    ORDER BY m.MatchDate DESC, m.MatchId DESC
);
GO

/* =====================================================================
   ФУНКЦИЯ 3 (сложная). GetTeamPowerRating — рейтинг силы команды
   ---------------------------------------------------------------------
   Rating = WinRate * 100 + TotalPrizeMoney / 10000 + SponsorBudget / 5000
   WITH SCHEMABINDING: все объекты — по двухсоставным именам.
   ===================================================================== */
CREATE OR ALTER FUNCTION dbo.GetTeamPowerRating (@TeamId INT)
RETURNS DECIMAL(12,4)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @Played  INT,
            @Wins    INT,
            @WinRate DECIMAL(12,6),
            @Prize   DECIMAL(12,2),
            @Sponsor DECIMAL(12,2);

    SELECT @Played = COUNT(*),
           @Wins   = SUM(CASE WHEN m.WinnerId = @TeamId THEN 1 ELSE 0 END)
    FROM dbo.Matches AS m
    WHERE m.IsCompleted = 1
      AND (m.Team1Id = @TeamId OR m.Team2Id = @TeamId);

    SET @WinRate = CASE WHEN ISNULL(@Played, 0) = 0
                        THEN 0
                        ELSE CAST(@Wins AS DECIMAL(12,6)) / @Played END;

    SELECT @Prize = t.TotalPrizeMoney FROM dbo.Teams AS t WHERE t.TeamId = @TeamId;

    SELECT @Sponsor = SUM(ts.ContributionAmount)
    FROM dbo.TeamSponsors AS ts WHERE ts.TeamId = @TeamId;

    RETURN  @WinRate * 100
          + ISNULL(@Prize, 0)   / 10000
          + ISNULL(@Sponsor, 0) /  5000;
END
GO

/* =====================================================================
   ТРИГГЕР 1 (простой). TR_Teams_PreventActiveDelete
   ---------------------------------------------------------------------
   AFTER DELETE на Teams: запрещает удалять активные команды.
   ===================================================================== */
CREATE OR ALTER TRIGGER dbo.TR_Teams_PreventActiveDelete
ON dbo.Teams
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM deleted WHERE IsActive = 1)
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50030, N'Нельзя удалить активную команду. Сначала деактивируйте её.', 1;
    END
END
GO

/* =====================================================================
   ТРИГГЕР 2 (средний). TR_Matches_AutoStats
   ---------------------------------------------------------------------
   AFTER UPDATE на Matches: при переходе IsCompleted 0 -> 1 создаёт
   нулевые «заготовки» статистики для всех игроков обеих команд.
   Дубли исключены проверкой NOT EXISTS.
   ===================================================================== */
CREATE OR ALTER TRIGGER dbo.TR_Matches_AutoStats
ON dbo.Matches
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- реагируем только на изменение поля IsCompleted
    IF NOT UPDATE(IsCompleted) RETURN;

    INSERT dbo.PlayerMatchStats (PlayerId, MatchId, Kills, Deaths, Assists, IsMVP)
    SELECT p.PlayerId, i.MatchId, 0, 0, 0, 0
    FROM inserted AS i
    JOIN deleted  AS d ON d.MatchId = i.MatchId
    JOIN dbo.Players AS p
      ON p.TeamId IN (i.Team1Id, i.Team2Id)
    WHERE d.IsCompleted = 0 AND i.IsCompleted = 1      -- именно переход 0 -> 1
      AND NOT EXISTS (SELECT 1 FROM dbo.PlayerMatchStats AS s
                       WHERE s.PlayerId = p.PlayerId AND s.MatchId = i.MatchId);
END
GO

/* =====================================================================
   ПРЕДСТАВЛЕНИЕ + ТРИГГЕР 3 (сложный). Трансфер игрока
   ===================================================================== */
CREATE OR ALTER VIEW dbo.vw_PlayerTransfers
AS
SELECT p.PlayerId,
       p.Nickname,
       p.RealName,
       p.Country,
       p.BirthDate,
       p.TeamId,
       t.Name     AS TeamName,
       t.Country  AS TeamCountry,
       t.IsActive AS TeamIsActive
FROM dbo.Players AS p
LEFT JOIN dbo.Teams AS t ON t.TeamId = p.TeamId;
GO

/* ---------------------------------------------------------------------
   INSTEAD OF UPDATE: обновляется ТОЛЬКО TeamId, остальные поля игнорируются.
   Проверки: команда существует и активна; в ней < 5 игроков;
             игрок не переходит в ту же команду.
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.TR_vw_PlayerTransfers_Update
ON dbo.vw_PlayerTransfers
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(TeamId) RETURN;          -- другие поля через представление не меняем

    -- 1. Переход в ту же самую команду
    IF EXISTS (SELECT 1 FROM inserted AS i
               JOIN deleted AS d ON d.PlayerId = i.PlayerId
               WHERE ISNULL(i.TeamId, -1) = ISNULL(d.TeamId, -1))
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50040, N'Игрок уже состоит в этой команде.', 1;
    END

    -- 2. Команда существует и активна
    IF EXISTS (SELECT 1 FROM inserted AS i
               WHERE i.TeamId IS NOT NULL
                 AND NOT EXISTS (SELECT 1 FROM dbo.Teams AS t
                                  WHERE t.TeamId = i.TeamId AND t.IsActive = 1))
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50041, N'Команда не найдена или неактивна.', 1;
    END

    -- 3. Состав новой команды: не больше 5 игроков
    IF EXISTS (
        SELECT 1
        FROM (SELECT i.TeamId, COUNT(*) AS Incoming
              FROM inserted AS i
              WHERE i.TeamId IS NOT NULL
              GROUP BY i.TeamId) AS n
        WHERE n.Incoming
            + (SELECT COUNT(*) FROM dbo.Players AS p
                WHERE p.TeamId = n.TeamId
                  AND p.PlayerId NOT IN (SELECT PlayerId FROM inserted)) > 5)
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 50042, N'Состав заполнен.', 1;
    END

    -- 4. Все проверки пройдены — выполняем сам перевод
    UPDATE p
       SET p.TeamId = i.TeamId
    FROM dbo.Players AS p
    JOIN inserted AS i ON i.PlayerId = p.PlayerId;
END
GO
PRINT N'Созданы 3 процедуры, 3 функции, 1 представление и 3 триггера.';
GO
