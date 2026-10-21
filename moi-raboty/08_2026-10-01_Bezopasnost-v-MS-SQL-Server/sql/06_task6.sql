/* =====================================================================
   Задача 6. Попытка эскалации прав
   ===================================================================== */
USE MyDB;
GO
EXECUTE AS USER = 'Reader';
GO                 -- правка: CREATE PROCEDURE обязан быть первым в пакете
CREATE PROCEDURE TestProc AS SELECT 'Hello';
GO
REVERT;
GO
