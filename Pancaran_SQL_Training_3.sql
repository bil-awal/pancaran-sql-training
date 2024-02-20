CREATE OR REPLACE FUNCTION trn_function(p_action character varying)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100
	VOLATILE PARALLEL UNSAFE 
AS $BODY$

DECLARE
	l_context text;
	j_result text;

BEGIN
	IF (p_action = 'event_log') THEN
		SELECT JSON_AGG(rts)::text INTO j_result
			-- SELECT id, name, nik INTO vId, vName, vNik  
		FROM (
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
		) rts;
		
		RETURN '{"resultCode":1, "message":"Success", "items": '||j_result::json||' }';
	END IF;
	RETURN '{"resultCode":0, "message":"p_action not found"}';
	EXCEPTION WHEN OTHERS THEN 
		GET STACKED DIAGNOSTICS l_context = PG_EXCEPTION_CONTEXT;
		SELECT row_to_json(xx) INTO j_result FROM (SELECT -1 "resultCode", concat(SQLERRM, l_context) "message") xx;
		RETURN j_result;
END;

$BODY$;