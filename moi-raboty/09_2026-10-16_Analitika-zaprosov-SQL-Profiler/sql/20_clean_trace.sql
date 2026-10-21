DECLARE @TraceID INT, @rc INT, @on BIT=1, @mf BIGINT=50;
DECLARE @file NVARCHAR(256)=N'/var/opt/mssql/trace/$RUN$';
EXEC @rc = sp_trace_create @TraceID OUTPUT, 0, @file, @mf, NULL;
DECLARE @e TABLE(id INT); INSERT INTO @e VALUES (10),(12),(98),(146);
DECLARE @c TABLE(id INT); INSERT INTO @c VALUES (1),(13),(16),(18),(10),(12),(14),(15),(35),(51);
DECLARE @ev INT,@col INT;
DECLARE ce CURSOR FAST_FORWARD FOR SELECT id FROM @e; OPEN ce; FETCH NEXT FROM ce INTO @ev;
WHILE @@FETCH_STATUS=0 BEGIN
  DECLARE cc CURSOR FAST_FORWARD FOR SELECT id FROM @c; OPEN cc; FETCH NEXT FROM cc INTO @col;
  WHILE @@FETCH_STATUS=0 BEGIN EXEC sp_trace_setevent @TraceID,@ev,@col,@on; FETCH NEXT FROM cc INTO @col; END
  CLOSE cc; DEALLOCATE cc; FETCH NEXT FROM ce INTO @ev; END
CLOSE ce; DEALLOCATE ce;
EXEC sp_trace_setfilter @TraceID, 35, 0, 6, N'TrainingDB';
EXEC sp_trace_setstatus @TraceID, 1;
SELECT @TraceID AS TraceID;
