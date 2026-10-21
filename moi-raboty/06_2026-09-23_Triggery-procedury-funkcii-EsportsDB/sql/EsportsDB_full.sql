/* =====================================================================
   ПРАКТИЧЕСКАЯ РАБОТА: Триггеры, процедуры, функции
   Предметная область: киберспортивная турнирная платформа
   Файл 1 из 4 — схема БД и тестовые данные (выданы в задании)
   ===================================================================== */
USE master;
GO
IF DB_ID('EsportsDB') IS NOT NULL
BEGIN
    ALTER DATABASE EsportsDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE EsportsDB;
END
GO
CREATE DATABASE EsportsDB;
GO
USE EsportsDB;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Команды
CREATE TABLE dbo.Teams (
    TeamId          INT IDENTITY(1,1) PRIMARY KEY,
    Name            NVARCHAR(100) NOT NULL UNIQUE,
    Country         NVARCHAR(50)  NOT NULL,
    FoundedDate     DATE          NOT NULL,
    TotalPrizeMoney DECIMAL(12,2) NOT NULL DEFAULT 0,
    IsActive        BIT           NOT NULL DEFAULT 1
);
GO
-- Игроки
CREATE TABLE dbo.Players (
    PlayerId  INT IDENTITY(1,1) PRIMARY KEY,
    Nickname  NVARCHAR(50)  NOT NULL UNIQUE,
    RealName  NVARCHAR(100) NOT NULL,
    Country   NVARCHAR(50)  NOT NULL,
    BirthDate DATE          NOT NULL,
    TeamId    INT           NULL,
    CONSTRAINT FK_Players_Teams FOREIGN KEY (TeamId) REFERENCES dbo.Teams(TeamId)
);
GO
-- Турниры
CREATE TABLE dbo.Tournaments (
    TournamentId INT IDENTITY(1,1) PRIMARY KEY,
    Name         NVARCHAR(200) NOT NULL,
    Game         NVARCHAR(50)  NOT NULL,
    StartDate    DATE          NOT NULL,
    EndDate      DATE          NOT NULL,
    PrizePool    DECIMAL(12,2) NOT NULL,
    Status       NVARCHAR(20)  NOT NULL DEFAULT 'Scheduled'
        CHECK (Status IN ('Scheduled','InProgress','Completed','Cancelled'))
);
GO
-- Спонсоры
CREATE TABLE dbo.Sponsors (
    SponsorId INT IDENTITY(1,1) PRIMARY KEY,
    Name      NVARCHAR(100) NOT NULL UNIQUE,
    Budget    DECIMAL(12,2) NOT NULL
);
GO
-- Спонсорство команд (M:N)
CREATE TABLE dbo.TeamSponsors (
    TeamId             INT NOT NULL,
    SponsorId          INT NOT NULL,
    ContributionAmount DECIMAL(12,2) NOT NULL,
    CONSTRAINT PK_TeamSponsors PRIMARY KEY (TeamId, SponsorId),
    CONSTRAINT FK_TS_Team    FOREIGN KEY (TeamId)    REFERENCES dbo.Teams(TeamId),
    CONSTRAINT FK_TS_Sponsor FOREIGN KEY (SponsorId) REFERENCES dbo.Sponsors(SponsorId)
);
GO
-- Матчи
CREATE TABLE dbo.Matches (
    MatchId      INT IDENTITY(1,1) PRIMARY KEY,
    TournamentId INT  NOT NULL,
    Round        INT  NOT NULL,
    Team1Id      INT  NOT NULL,
    Team2Id      INT  NOT NULL,
    MatchDate    DATE NOT NULL,
    Team1Score   INT  NULL,
    Team2Score   INT  NULL,
    WinnerId     INT  NULL,
    IsCompleted  BIT  NOT NULL DEFAULT 0,
    CONSTRAINT FK_Matches_Tournament FOREIGN KEY (TournamentId) REFERENCES dbo.Tournaments(TournamentId),
    CONSTRAINT FK_Matches_Team1 FOREIGN KEY (Team1Id) REFERENCES dbo.Teams(TeamId),
    CONSTRAINT FK_Matches_Team2 FOREIGN KEY (Team2Id) REFERENCES dbo.Teams(TeamId),
    CONSTRAINT CHK_Matches_Teams CHECK (Team1Id <> Team2Id)
);
GO
-- Статистика игроков по матчам
CREATE TABLE dbo.PlayerMatchStats (
    PlayerId INT NOT NULL,
    MatchId  INT NOT NULL,
    Kills    INT NOT NULL DEFAULT 0,
    Deaths   INT NOT NULL DEFAULT 0,
    Assists  INT NOT NULL DEFAULT 0,
    IsMVP    BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_PlayerMatchStats PRIMARY KEY (PlayerId, MatchId),
    CONSTRAINT FK_PMS_Player FOREIGN KEY (PlayerId) REFERENCES dbo.Players(PlayerId),
    CONSTRAINT FK_PMS_Match  FOREIGN KEY (MatchId)  REFERENCES dbo.Matches(MatchId),
    CONSTRAINT CHK_PMS_Stats CHECK (Kills >= 0 AND Deaths >= 0 AND Assists >= 0)
);
GO
-- Распределение призовых
CREATE TABLE dbo.PrizeDistributions (
    TournamentId INT NOT NULL,
    TeamId       INT NOT NULL,
    Placement    INT NOT NULL,
    Amount       DECIMAL(12,2) NOT NULL,
    CONSTRAINT PK_PrizeDistributions PRIMARY KEY (TournamentId, TeamId),
    CONSTRAINT FK_PD_Tournament FOREIGN KEY (TournamentId) REFERENCES dbo.Tournaments(TournamentId),
    CONSTRAINT FK_PD_Team FOREIGN KEY (TeamId) REFERENCES dbo.Teams(TeamId),
    CONSTRAINT CHK_PD_Placement CHECK (Placement >= 1 AND Placement <= 3)
);
GO
PRINT N'Схема EsportsDB создана.';
GO
/* Файл 2 из 4 — тестовые данные (из задания) */
USE EsportsDB;
GO
SET NOCOUNT ON;
INSERT dbo.Teams (Name, Country, FoundedDate, TotalPrizeMoney, IsActive) VALUES
 (N'Nexus Gaming',  N'Россия',      '2020-03-01', 150000.00, 1),
 (N'Phoenix Reign', N'Бразилия',    '2019-06-15', 280000.00, 1),
 (N'Void Hunters',  N'Швеция',      '2021-01-10',  95000.00, 1),
 (N'Silent Storm',  N'Южная Корея', '2018-11-20', 520000.00, 1),
 (N'Echo Squad',    N'США',         '2022-04-05',  12000.00, 0);

INSERT dbo.Players (Nickname, RealName, Country, BirthDate, TeamId) VALUES
 (N'Fade',        N'Иван Морозов',     N'Россия',      '2001-05-12', 1),
 (N'ShadowBlade', N'Дмитрий Соколов',  N'Россия',      '2000-08-23', 1),
 (N'Lumin',       N'Анна Лебедева',    N'Россия',      '2002-01-03', 1),
 (N'Kraken',      N'Артём Волков',     N'Россия',      '1999-12-15', 1),
 (N'Hexen',       N'Михаил Орлов',     N'Россия',      '2001-07-07', 1),
 (N'FuryBR',      N'Лукас Сильва',     N'Бразилия',    '2000-03-30', 2),
 (N'Vortex',      N'Педро Соуса',      N'Бразилия',    '2001-09-14', 2),
 (N'BlitzKrieg',  N'Рафаэль Лима',     N'Бразилия',    '1999-04-22', 2),
 (N'Spectre',     N'Габриэл Коста',    N'Бразилия',    '2002-02-18', 2),
 (N'Overlord',    N'Тиаго Мендеш',     N'Бразилия',    '2000-11-01', 2),
 (N'Frostbite',   N'Эрик Лундберг',    N'Швеция',      '2001-06-25', 3),
 (N'Pulse',       N'Юнатан Берг',      N'Швеция',      '2000-10-09', 3),
 (N'Rift',        N'Оскар Нильссон',   N'Швеция',      '2002-03-17', 3),
 (N'Shimmer',     N'Уильям Карлссон',  N'Швеция',      '1999-08-30', 3),
 (N'Dusk',        N'Лиам Эрикссон',    N'Швеция',      '2001-12-05', 3),
 (N'KimchiGod',   N'Ким Тэхён',        N'Южная Корея', '1998-04-11', 4),
 (N'Nightshade',  N'Пак Джиён',        N'Южная Корея', '2000-02-25', 4),
 (N'Zenith',      N'Ли Минхо',         N'Южная Корея', '1999-07-19', 4),
 (N'Stormcaller', N'Чой Юна',          N'Южная Корея', '2001-09-08', 4),
 (N'Eclipse',     N'Чжан Вонхо',       N'Южная Корея', '2000-12-21', 4);

INSERT dbo.Tournaments (Name, Game, StartDate, EndDate, PrizePool, Status) VALUES
 (N'Winter Championship 2025', N'Dota 2', '2025-12-01', '2025-12-15', 500000.00, 'InProgress');

INSERT dbo.Sponsors (Name, Budget) VALUES
 (N'Red Bull Gaming', 1000000.00),
 (N'Logitech Pro',     500000.00),
 (N'Razer',            750000.00);

INSERT dbo.TeamSponsors (TeamId, SponsorId, ContributionAmount) VALUES
 (1,1,50000.00),(1,2,30000.00),(2,1,80000.00),(2,3,45000.00),(3,2,20000.00),(4,3,120000.00);

INSERT dbo.Matches (TournamentId, Round, Team1Id, Team2Id, MatchDate, Team1Score, Team2Score, WinnerId, IsCompleted) VALUES
 (1, 1, 1, 3, '2025-12-01', 2, 0, 1, 1),        -- Nexus 2:0 Void
 (1, 1, 2, 4, '2025-12-02', 1, 2, 4, 1),        -- Phoenix 1:2 Silent Storm
 (1, 2, 1, 4, '2025-12-05', NULL, NULL, NULL, 0), -- финал
 (1, 2, 3, 2, '2025-12-06', NULL, NULL, NULL, 0); -- матч за 3-е место

INSERT dbo.PlayerMatchStats (PlayerId, MatchId, Kills, Deaths, Assists, IsMVP) VALUES
 (1,1,15,3,7,1),(2,1,8,5,12,0),(3,1,4,2,15,0),(4,1,11,4,6,0),(5,1,9,3,8,0),
 (6,2,10,8,4,0),(7,2,7,6,9,0),(8,2,12,5,3,1),(9,2,3,9,6,0),(10,2,6,7,10,0),
 (16,2,14,2,11,0),(17,2,9,4,8,0),(18,2,16,3,5,1),(19,2,7,6,9,0),(20,2,11,5,7,0);
GO
PRINT N'Тестовые данные загружены.';
SELECT 'Teams' AS T, COUNT(*) AS Cnt FROM dbo.Teams
UNION ALL SELECT 'Players', COUNT(*) FROM dbo.Players
UNION ALL SELECT 'Matches', COUNT(*) FROM dbo.Matches
UNION ALL SELECT 'PlayerMatchStats', COUNT(*) FROM dbo.PlayerMatchStats;
GO
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
