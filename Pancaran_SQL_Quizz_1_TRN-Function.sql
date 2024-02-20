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
        
    ELSIF (p_action = 'list_roster') THEN
        SELECT JSON_AGG(rts)::text INTO j_result
        FROM (
            SELECT
                m_personnel.nik,
                m_personnel.name,
                (
                    SELECT JSON_AGG(roster_item) FROM (
                        SELECT
                            roster_setup_group.date_from,
                            roster_setup_group.date_to,
                            roster_setup_group.docno,
                            roster_setup.name AS roster_name,
                            roster_setup_pattern.numof_days,
                            roster_setup_pattern.seqno AS pattern_seqno,
                            roster_setup_pattern.shift_id,
                            roster_setup_pattern.workshop_id
                        FROM
                            roster_setup_person
                            JOIN roster_setup ON roster_setup_person.setup_id = roster_setup.id
                            JOIN roster_setup_pattern ON roster_setup.id = roster_setup_pattern.setup_id
                            JOIN roster_setup_group ON roster_setup.group_id = roster_setup_group.id
                        WHERE
                            roster_setup_person.personnel_id = m_personnel.id
                        ORDER BY
                            roster_setup_pattern.seqno
                    ) roster_item
                ) AS roster_data
            FROM
                m_personnel
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
