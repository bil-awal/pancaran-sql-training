/**
Function

*/

DO LANGUAGE plpgsql
$$DECLARE
	cur record;
  	vcount int := 0;
  
BEGIN
	FOR cur IN 
		SELECT * FROM event_log WHERE action = 'IN'
	LOOP
		vcount := vcount+1;
	END LOOP;
	
  	RAISE INFO 'Total Event Log In = %.', vcount;
END$$;

CREATE OR REPLACE FUNCTION public.house_keeping()
RETURNS text
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	CUR record;
	vCount int := 0;
	
BEGIN
	FOR CUR IN
		SELECT id FROM gps_log WHERE age(now(), logtime) >