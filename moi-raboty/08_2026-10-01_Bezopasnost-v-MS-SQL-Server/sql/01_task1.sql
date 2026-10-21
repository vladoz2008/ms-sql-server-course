/* Задача 1. Создать пользователей и проверить их права */
USE MyDB;
GO
CREATE USER Reader WITHOUT LOGIN;
CREATE USER Writer WITHOUT LOGIN;

GRANT SELECT ON Students TO Reader;
GRANT INSERT ON Students TO Writer;
GO
-- Проверка Reader
EXECUTE AS USER = 'Reader';
SELECT * FROM Students;
INSERT INTO Students VALUES (10,'Test',20,1);
REVERT;
GO
-- Проверка Writer
EXECUTE AS USER = 'Writer';
INSERT INTO Students VALUES (11,'Writer Test',21,1);
SELECT * FROM Students;
REVERT;
GO
