DECLARE @id INT = (SELECT TOP 1 id FROM sys.traces WHERE path LIKE '%$RUN$%');
IF @id IS NOT NULL
BEGIN
    EXEC sp_trace_setstatus @id, 0;
    EXEC sp_trace_setstatus @id, 2;
    PRINT 'trace stopped';
END
ELSE PRINT 'trace not found';
