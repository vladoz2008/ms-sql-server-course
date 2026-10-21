/* Серверная трассировка с тем же определением, что в Profiler (шаг 2 методички) */
DECLARE @rc INT, @TraceID INT, @maxfilesize BIGINT = 50, @on BIT = 1;
DECLARE @file NVARCHAR(256) = N'/var/opt/mssql/trace/$RUN$';

EXEC @rc = sp_trace_create @TraceID OUTPUT, 0, @file, @maxfilesize, NULL;
IF (@rc <> 0) BEGIN PRINT 'sp_trace_create failed, rc=' + CAST(@rc AS VARCHAR); RETURN; END

/* События: 10 RPC:Completed, 12 SQL:BatchCompleted, 98 Showplan Statistics Profile,
   146 Showplan XML Statistics Profile, 24 Lock:Acquired */
DECLARE @e TABLE(id INT);  INSERT INTO @e VALUES (10),(12),(98),(146),(24);
/* Столбцы: 1 TextData, 13 Duration, 16 Reads, 18 CPU + служебные 10,12,14,15,22,35,51 */
DECLARE @c TABLE(id INT);  INSERT INTO @c VALUES (1),(13),(16),(18),(10),(12),(14),(15),(22),(35),(51);

DECLARE @ev INT, @col INT;
DECLARE ce CURSOR FAST_FORWARD FOR SELECT id FROM @e;
OPEN ce; FETCH NEXT FROM ce INTO @ev;
WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE cc CURSOR FAST_FORWARD FOR SELECT id FROM @c;
    OPEN cc; FETCH NEXT FROM cc INTO @col;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC sp_trace_setevent @TraceID, @ev, @col, @on;
        FETCH NEXT FROM cc INTO @col;
    END
    CLOSE cc; DEALLOCATE cc;
    FETCH NEXT FROM ce INTO @ev;
END
CLOSE ce; DEALLOCATE ce;

/* Фильтры: DatabaseName LIKE 'TrainingDB'  и  Duration >= 100 мс
   ВНИМАНИЕ: в sp_trace_setfilter Duration задаётся в МИКРОсекундах */
EXEC sp_trace_setfilter @TraceID, 35, 0, 6, N'TrainingDB';
DECLARE @dur BIGINT = 100000;
EXEC sp_trace_setfilter @TraceID, 13, 0, 4, @dur;

EXEC sp_trace_setstatus @TraceID, 1;
SELECT @TraceID AS TraceID, @file AS TraceFile;
