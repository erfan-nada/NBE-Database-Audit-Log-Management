-- Set up variables and remove old job (safe to rerun)
USE msdb;
GO

DECLARE 
    @job_id UNIQUEIDENTIFIER,
    @job_name SYSNAME = N'TLog_DB1_DB2_Every5min_1Hour_Rolling50Min',
    @backup_dir NVARCHAR(4000),
    @startDT DATETIME2(0) = SYSDATETIME(),
    @endDT   DATETIME2(0) = DATEADD(MINUTE, 60, SYSDATETIME()),
    @startDate INT,
    @startTime INT,
    @endDate   INT,
    @endTime   INT;

-- Change this path if you want
SET @backup_dir = COALESCE(CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(4000)),
                           N'C:\NBE Database Project\Transaction_Log_Backup');

SET @startDate = CONVERT(INT, CONVERT(CHAR(8), @startDT, 112));
SET @startTime = CONVERT(INT, REPLACE(CONVERT(CHAR(8), @startDT, 108), ':',''));
SET @endDate   = CONVERT(INT, CONVERT(CHAR(8), @endDT,   112));
SET @endTime   = CONVERT(INT, REPLACE(CONVERT(CHAR(8), @endDT,   108), ':',''));

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @job_name)
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = @job_name, @delete_unused_schedule=1;
END


--2) Create the empty job

DECLARE @job_id UNIQUEIDENTIFIER, @job_name SYSNAME = N'TLog_DB1_DB2_Every5min_1Hour_Rolling50Min';

EXEC msdb.dbo.sp_add_job
    @job_name = @job_name,
    @enabled = 1,
    @delete_level = 1, -- auto-delete on success; use 0 if you want to keep it after
    @description = N'Transaction log backups for DB1 & DB2 every 5 minutes for one hour; deletes files older than 50 minutes.',
    @job_id = @job_id OUTPUT;

-- 3) Add Step 1: the LOG backups

DECLARE @job_id UNIQUEIDENTIFIER = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'TLog_DB1_DB2_Every5min_1Hour_Rolling50Min');
DECLARE @backup_dir NVARCHAR(4000) = COALESCE(CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(4000)),
                                              N'C:\NBE Database Project\Transaction_Log_Backup');

DECLARE @backup_step NVARCHAR(MAX) = N'
DECLARE @dir NVARCHAR(4000) = N''' + @backup_dir + N''';

-- Pattern: DBName_YYYYMMDD_HHMMSS.trn (uses server time)
DECLARE @f1 NVARCHAR(4000) = @dir + ''\DB1_'' + CONVERT(CHAR(8), GETDATE(), 112) + ''_'' + REPLACE(CONVERT(CHAR(8), GETDATE(),108),'':'','''') + ''.trn'';
DECLARE @f2 NVARCHAR(4000) = @dir + ''\DB2_'' + CONVERT(CHAR(8), GETDATE(), 112) + ''_'' + REPLACE(CONVERT(CHAR(8), GETDATE(),108),'':'','''') + ''.trn'';

BACKUP LOG DB1 TO DISK = @f1 WITH INIT, COMPRESSION, CHECKSUM, STATS = 5;
BACKUP LOG DB2 TO DISK = @f2 WITH INIT, COMPRESSION, CHECKSUM, STATS = 5;
';

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @job_id,
    @step_name = N'Backup LOGs (DB1 & DB2)',
    @subsystem = N'TSQL',
    @command = @backup_step,
    @retry_attempts = 0,
    @on_success_action = 3,  -- go to next step
    @on_fail_action = 2;     -- quit with failure


-- 4) Add Step 2: cleanup files older than 50 minutes
DECLARE @job_id UNIQUEIDENTIFIER = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'TLog_DB1_DB2_Every5min_1Hour_Rolling50Min');
DECLARE @backup_dir NVARCHAR(4000) = COALESCE(CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(4000)),
                                              N'C:\NBE Database Project\Transaction_Log_Backup');

DECLARE @ps NVARCHAR(MAX) = N'
$ErrorActionPreference = ''Stop''
$dir = "' + REPLACE(@backup_dir, '"', '\"') + '"
if (!(Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
Get-ChildItem -LiteralPath $dir -Filter *.trn -File |
  Where-Object { $_.LastWriteTime -lt (Get-Date).AddMinutes(-50) } |
  Remove-Item -Force
';

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @job_id,
    @step_name = N'Cleanup .trn older than 50 minutes',
    @subsystem = N'PowerShell',
    @command = @ps,
    @retry_attempts = 0,
    @on_success_action = 1,  -- quit with success
    @on_fail_action = 2;


	-- 5) Create and attach the 5-minute schedule (1-hour window)

	DECLARE 
    @job_id UNIQUEIDENTIFIER = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'TLog_DB1_DB2_Every5min_1Hour_Rolling50Min'),
    @schedule_name SYSNAME = N'Every5min_OneHourWindow',
    @startDT DATETIME2(0) = SYSDATETIME(),
    @endDT   DATETIME2(0) = DATEADD(MINUTE, 60, SYSDATETIME()),
    @startDate INT, @startTime INT, @endDate INT, @endTime INT;

SET @startDate = CONVERT(INT, CONVERT(CHAR(8), @startDT, 112));
SET @startTime = CONVERT(INT, REPLACE(CONVERT(CHAR(8), @startDT, 108), ':',''));
SET @endDate   = CONVERT(INT, CONVERT(CHAR(8), @endDT,   112));
SET @endTime   = CONVERT(INT, REPLACE(CONVERT(CHAR(8), @endDT,   108), ':',''));

-- If schedule exists, drop and recreate (optional)
IF EXISTS (SELECT 1 FROM msdb.dbo.sysschedules WHERE name = @schedule_name)
BEGIN
    EXEC msdb.dbo.sp_delete_schedule @schedule_name = @schedule_name;
END

EXEC msdb.dbo.sp_add_schedule
    @schedule_name = @schedule_name,
    @enabled = 1,
    @freq_type = 4,           -- daily
    @freq_interval = 1,
    @freq_subday_type = 4,    -- minutes
    @freq_subday_interval = 5,
    @active_start_date = @startDate,
    @active_start_time = @startTime,
    @active_end_date = @endDate,
    @active_end_time = @endTime;

EXEC msdb.dbo.sp_attach_schedule
    @job_id = @job_id,
    @schedule_name = @schedule_name;

--start job 
EXEC msdb.dbo.sp_start_job 
  @job_name = N'TLog_DB1_DB2_Every5min_1Hour_Rolling50Min';

  --

--


--verify
	SELECT TOP (50) database_name, physical_device_name, backup_start_date, backup_finish_date, type
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE type = 'L' AND database_name IN ('DB1','DB2')
ORDER BY backup_finish_date DESC;


--

USE msdb;
GO

-- Option A: attach to the local server using the built-in alias
EXEC msdb.dbo.sp_add_jobserver
    @job_name   = N'TLog_DB1_DB2_Every5min_1Hour_Rolling50Min',
    @server_name = N'DESKTOP-60E0V9F';  -- or see Option B below
GO
select @@SERVERNAME
-- Option B (if (LOCAL) doesn’t work), attach by explicit server name
-- First check your server name:
 SELECT @@SERVERNAME;
 --Then plug it in here:
EXEC msdb.dbo.sp_add_jobserver
     @job_name   = N'TLog_DB1_DB2_Every5min_1Hour_Rolling50Min',
     @server_name = N'DESKTOP-60E0V9F';
--GO