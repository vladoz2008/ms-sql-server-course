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
