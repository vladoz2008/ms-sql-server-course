/* =====================================================================
   Задача 2. Ограничение доступа через представление
   ===================================================================== */
USE MyDB;
GO
CREATE OR ALTER VIEW StudentsPublic AS
SELECT FullName, GroupID FROM Students;
GO
GRANT SELECT ON StudentsPublic TO Reader;
-- Правка: в задаче 1 пользователю Reader уже выдали SELECT на всю таблицу
-- Students. Пока это право действует, скрыть данные представлением невозможно.
REVOKE SELECT ON Students FROM Reader;
GO
EXECUTE AS USER = 'Reader';
SELECT * FROM StudentsPublic;
SELECT * FROM Students;
REVERT;
GO
