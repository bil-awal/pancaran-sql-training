-- Work Order
-- -- Event Log
SELECT 
	event_log.actor_type, 
	m_personnel.name AS actor, 
	event_log.domain, 
	event_log.action, 
	event_log.status, 
	event_log.pause_reason, 
	event_log.data_iden, 
	event_log.duration,
	event_log.via,
	em_workshop.name AS workshop,
	event_log.tstamp
FROM event_log
LEFT JOIN m_personnel ON event_log.actor_id = m_personnel.id
LEFT JOIN em_workshop ON event_log.workshop_id = em_workshop.id
LIMIT 100;


-- -- Event Log / Jumlah Mechanic Yang Masuk Per Hari Ini Berdasarkan Grade
SELECT m_personnel.grade, COUNT(*)
FROM event_log
LEFT JOIN m_personnel ON event_log.actor_id = m_personnel.id
WHERE event_log.action = 'IN' AND 
event_log.tstamp::date = '2024-02-19'::date
GROUP BY m_personnel.grade


-- -- JSON SQL / Mencari Mechanic A Berdasarkan Absen
SELECT ROW_TO_JSON(rts) report FROM (
	SELECT m_personnel.nik, m_personnel.name, evn.logs
	FROM m_personnel
	JOIN LATERAL (
		SELECT JSON_AGG(agre) logs FROM (
			SELECT event_log.action, event_log.tstamp
			FROM event_log
			WHERE event_log.actor_id = m_personnel.id
			ORDER BY event_log.tstamp DESC
		) agre
	) evn ON TRUE
) rts

