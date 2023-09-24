--have in mind parts of code have been purousely deleted


CREATE PROCEDURE ProjectReport (IN ProjectName NVARCHAR(100))

LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS

ProjectEntry int;
i int := 0;
j int := 0;
IsExists INTEGER := 0;

CURSOR cursor1 
FOR

SELECT
	node_id
	FROM HIERARCHY 
	(
		SOURCE (
				SELECT 
				T0."AbsEntry" as node_id,		
				T0."ParentID" as parent_id
				FROM OPHA T0		
				WHERE T0."ProjectID" = ProjectEntry
				ORDER BY T0."Code"
				)
	); 
	
CURSOR cursor2 
FOR
SELECT "POS" 
FROM PMG1
WHERE "AbsEntry" = ProjectEntry;
	
BEGIN

	SELECT T0."AbsEntry" INTO ProjectEntry
	FROM OPMG T0
	WHERE T0."NAME" = ProjectName;

	SELECT COUNT(*) INTO IsExists 
	FROM M_TEMPORARY_TABLES
	WHERE TABLE_NAME = '#TEMP_TABLE_1' AND SCHEMA_NAME = CURRENT_SCHEMA and connection_id = current_connection; 
	
	IF :IsExists > 0 THEN
		DROP TABLE #TEMP_TABLE_1;
	END IF;
	
	CREATE LOCAL TEMPORARY COLUMN TABLE #TEMP_TABLE_1 
	(
		"Project/Subproject" NVARCHAR(254),
		"Stage" NVARCHAR(100),
		"Task" NVARCHAR(100),
		"Description" NVARCHAR(5000), 
		"Remarks" NVARCHAR(200), 
		"Work Order" NVARCHAR(100), 
		"Resource" NVARCHAR(100), 
		"Activity" NVARCHAR(100), 
		"Start Date" DATE, 
		"Due Date" DATE, 
		"Finished Date" DATE, 
		"Progress" DECIMAL(19,6), 
		"Completed" VARCHAR(1), 
		"Owner" NVARCHAR(100)
	);
	
	INSERT INTO #TEMP_TABLE_1
	(
		SELECT 
		T0."NAME",
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		T0."START",
		T0."DUEDATE",
		T0."CLOSING",
		T0."FINISHED",
		NULL,
		T1."firstName" || T1."lastName"
		FROM OPMG T0 
		LEFT OUTER JOIN OHEM T1
		ON T0."OWNER" = T1."Code"
		WHERE T0."AbsEntry" = ProjectEntry
	);

	OPEN cursor2;	

	FETCH cursor2 INTO j;	

	WHILE NOT cursor2::NOTFOUND 
	DO
	INSERT INTO #TEMP_TABLE_1
	(
		SELECT 
		NULL,
		T3."Name",
		T4."Name",
		T2."DSCRIPTION",
		--*
		NULL,
		NULL,
		NULL,
		T2."START",
		T2."CLOSE", 
		T2."FINISHDATE", 
		NULL, 
		T2."FINISH",
		T1."firstName" || T1."lastName"
		FROM PMG1 T2
		LEFT OUTER JOIN OHEM T1
		ON T2."OWNER" = T1."Code"
		LEFT OUTER JOIN PMC2 T3
		ON T2."StageID" = T3."StageID"
		LEFT OUTER JOIN PMC6 T4
		ON T2."Task" = T4."TaskID"
		WHERE T2."AbsEntry" = ProjectEntry AND T2."POS" = j
		
		UNION ALL
		
		SELECT 
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		T0."DocEntry",
		T2."ItemCode",
		NULL,
		T1."StartDate",
		T1."DueDate",
		NULL,
		NULL,
		NULL,
		NULL
		FROM PMG7 T0
		LEFT OUTER JOIN OWOR T1
		ON T0."DocEntry" = T1."DocEntry"
		LEFT OUTER JOIN WOR1 T2
		ON T1."DocEntry" = T2."DocEntry"
		WHERE T0."AbsEntry" = ProjectEntry AND T0."StageID" = j
		AND T2."ItemType" = 290 

		UNION ALL

		SELECT 
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		T1."ClgCode",
		T1."Recontact",
		T1."endDate",
		NULL,
		NULL,
		NULL,
		NULL
		FROM PMG6 T0
		LEFT OUTER JOIN OCLG T1
		ON T0."ACTIVITYID" = T1."ClgCode"	
		WHERE T0."AbsEntry" = ProjectEntry AND T0."StageID" = j
		);

		FETCH cursor2 INTO j;
		
	END WHILE; 
	
	CLOSE cursor2;
	
	OPEN cursor1;

	FETCH cursor1 INTO i;

	WHILE NOT cursor1::NOTFOUND 
		DO
		INSERT INTO #TEMP_TABLE_1
			(
				SELECT 
				T5."NAME",
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				T5."START",
				T5."DUEDATE",
				T5."END", 
				T5."FINISHED", 
				NULL,
				T1."firstName" || T1."lastName"  
				FROM OPHA T5 
				LEFT OUTER JOIN OHEM T1
				ON "OWNER" = T1."Code"
				WHERE T5."AbsEntry" = i
			
			UNION ALL
			
				SELECT 
				NULL, 
				T3."Name",
				T4."Name",
				T6."DSCRIPTION",
				--*
				NULL,
				NULL,
				NULL,
				T6."START",
				T6."CLOSE", 
				T6."FINISHDATE", 
				NULL, 
				T6."FINISH",
				T1."firstName" || T1."lastName" 
				FROM PHA1 T6 
				RIGHT OUTER JOIN OPHA T5
				ON T6."AbsEntry" = T5."AbsEntry"
				LEFT OUTER JOIN OHEM T1
				ON T6."OWNER" = T1."Code"
				LEFT OUTER JOIN PMC2 T3
				ON T6."StageID" = T3."StageID"
				LEFT OUTER JOIN PMC6 T4
				ON T6."Task" = T4."TaskID"
				WHERE T6."AbsEntry" = i
				
				UNION ALL
				
				SELECT 
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				T0."DocEntry",
				T2."ItemCode",
				NULL,
				T1."StartDate",
				T1."DueDate",
				NULL,
				NULL,
				NULL,
				NULL
				FROM PHA7 T0
				LEFT OUTER JOIN OWOR T1
				ON T0."DocEntry" = T1."DocEntry"
				LEFT OUTER JOIN WOR1 T2
				ON T1."DocEntry" = T2."DocEntry"
				WHERE T0."AbsEntry" = i 
				AND T2."ItemType" = 290 
					
				UNION ALL
					
				SELECT 
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				T1."ClgCode",
				T1."Recontact",
				T1."endDate",
				NULL,
				NULL,
				NULL,
				NULL
				FROM PHA6 T0
				LEFT OUTER JOIN OCLG T1
				ON T0."ACTIVITYID" = T1."ClgCode"	
				WHERE T0."AbsEntry" = i 	
			);

		FETCH cursor1 INTO i;
		
	END WHILE; 
	
	CLOSE cursor1;
	
	SELECT *
	FROM #TEMP_TABLE_1;

END;