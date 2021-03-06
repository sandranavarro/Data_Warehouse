

SELECT count(*) TOTAL_REGISTROS
, SUM(CASE WHEN length(TRIM(ID))<>0 THEN 1 ELSE 0 END) TOTAL_ID
, COUNT(DISTINCT CASE WHEN length(TRIM(ID))<>0 THEN ID ELSE NULL END) TOTAL_DIS_ID
, SUM(CASE WHEN length(TRIM(`ORDER`))<>0 THEN 1 ELSE 0 END) TOTAL_ORDER
, COUNT(DISTINCT CASE WHEN length(TRIM(`ORDER`))<>0 THEN `ORDER` ELSE NULL END) TOTAL_DIS_ORDER
, SUM(CASE WHEN length(TRIM(`PHASE`))<>0 THEN 1 ELSE 0 END) TOTAL_PHASE
, COUNT(DISTINCT CASE WHEN length(TRIM(`PHASE`))<>0 THEN `PHASE` ELSE NULL END) TOTAL_DIS_PHASE
, SUM(CASE WHEN length(TRIM(AGENT))<>0 THEN 1 ELSE 0 END) TOTAL_AGENT
, COUNT(DISTINCT CASE WHEN length(TRIM(AGENT))<>0 THEN AGENT ELSE NULL END) TOTAL_DIS_AGENT
, SUM(CASE WHEN length(TRIM(START_DT))<>0 THEN 1 ELSE 0 END) TOTAL_START_DT
, COUNT(DISTINCT CASE WHEN length(TRIM(START_DT))<>0 THEN START_DT ELSE NULL END) TOTAL_DIS_START_DT
, SUM(CASE WHEN length(TRIM(END_DT))<>0 THEN 1 ELSE 0 END) TOTAL_END_DT
, COUNT(DISTINCT CASE WHEN length(TRIM(END_DT))<>0 THEN END_DT ELSE NULL END) TOTAL_END_DT
FROM STAGE.STG_ORDERS_CRM;