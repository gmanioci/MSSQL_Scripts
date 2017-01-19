
-- Waits query for MSSQl 2016

WITH Waits AS
 (
 SELECT 
   wait_type, 
   wait_time_ms / 1000. AS wait_time_s,
   100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct,
   ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
 FROM sys.dm_os_wait_stats
 WHERE wait_type 
   NOT IN
     (-- filter out additional irrelevant waits
                        'BROKER_TASK_STOP', 'BROKER_RECEIVE_WAITFOR'
                        , 'BROKER_TO_FLUSH', 'BROKER_TRANSMITTER', 'CHECKPOINT_QUEUE'
                        , 'CHKPT', 'DISPATCHER_QUEUE_SEMAPHORE', 'CLR_AUTO_EVENT'
                        , 'CLR_MANUAL_EVENT','FT_IFTS_SCHEDULER_IDLE_WAIT', 'KSOURCE_WAKEUP' 
                        , 'LAZYWRITER_SLEEP', 'LOGMGR_QUEUE', 'MISCELLANEOUS', 'ONDEMAND_TASK_QUEUE'
                        , 'REQUEST_FOR_DEADLOCK_SEARCH', 'SLEEP_TASK', 'TRACEWRITE'
                        , 'SQLTRACE_BUFFER_FLUSH', 'XE_DISPATCHER_WAIT', 'XE_TIMER_EVENT'
                        , 'DIRTY_PAGE_POLL', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP'
                        , 'BROKER_EVENTHANDLER', 'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP'
                        , 'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', 'SP_SERVER_DIAGNOSTICS_SLEEP'
                        , 'HADR_FILESTREAM_IOMGR_IOCOMPLETION', 'HADR_WORK_QUEUE', 'HADR_NOTIFICATION_DEQUEUE'
                        , 'HADR_LOGCAPTURE_WAIT', 'HADR_CLUSAPI_CALL', 'HADR_TIMER_TASK', 'HADR_SYNC_COMMIT'
                        , 'PREEMPTIVE_SP_SERVER_DIAGNOSTICS', 'PREEMPTIVE_HADR_LEASE_MECHANISM'
                        ,'PREEMPTIVE_OS_GETFILEATTRIBUTES', 'PREEMPTIVE_OS_CREATEFILE', 'PREEMPTIVE_OS_FILEOPS'
                        , 'XE_LIVE_TARGET_TVF')
)
   
SELECT W1.wait_type,
 CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s,
 CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
 CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
FROM Waits AS W1
 INNER JOIN Waits AS W2 ON W2.rn <= W1.rn
GROUP BY W1.rn, 
 W1.wait_type, 
 W1.wait_time_s, 
 W1.pct
HAVING SUM(W2.pct) - W1.pct < 95; -- percentage threshold;