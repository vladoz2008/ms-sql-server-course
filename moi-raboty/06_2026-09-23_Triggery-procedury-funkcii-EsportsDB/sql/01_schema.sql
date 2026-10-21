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
