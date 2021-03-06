USE ODS;

-- POBLAR TABLA CANALES
-- ++++++++++++++++++++

INSERT INTO ODS_DM_CANALES (DE_CANAL, FC_INSERT, FC_MODIFICACION)
SELECT DISTINCT UPPER(TRIM(CHANNEL)), NOW(), NOW() 
FROM STAGE.STG_PRODUCTOS_CRM
WHERE LENGTH(TRIM(CHANNEL)) > 0;

INSERT INTO ODS_DM_CANALES VALUES (999, 'DESCONOCIDO', NOW(), NOW());
INSERT INTO ODS_DM_CANALES VALUES (998, 'NO APLICA', NOW(), NOW());

ANALYZE TABLE ODS_DM_CANALES;

-- POBLAR TABLA PRODUCTOS
-- ++++++++++++++++++++++

INSERT INTO ODS_DM_PRODUCTOS (DE_PRODUCTO, FC_INSERT, FC_MODIFICACION)
SELECT distinct UPPER(TRIM(PRODUCT_NAME)), NOW(), NOW() 
FROM STAGE.STG_PRODUCTOS_CRM
WHERE LENGTH(TRIM(PRODUCT_NAME)) > 0;

INSERT INTO ODS_DM_PRODUCTOS VALUES (999, 'DESCONOCIDO', NOW(), NOW());
INSERT INTO ODS_DM_PRODUCTOS VALUES (998, 'NO APLICA', NOW(), NOW());

ANALYZE TABLE ODS_DM_PRODUCTOS;

-- AÑADIR PAISES NUEVOS
-- ++++++++++++++++++++

INSERT INTO ODS_DM_PAISES 
SELECT DISTINCT UPPER(TRIM(REPLACE(PRODUCT_COUNTRY, "United States", "US"))) PAIS, NOW(), NOW()
FROM STAGE.STG_PRODUCTOS_CRM
LEFT JOIN ODS.ODS_DM_PAISES ON ODS.ODS_DM_PAISES.DE_PAIS = UPPER(TRIM(REPLACE(PRODUCT_COUNTRY, "United States", "US")))
WHERE ID_PAIS IS NULL AND LENGTH(TRIM(PRODUCT_COUNTRY)) > 0;

-- AÑADIR CIUDADES-ESTADO NUEVOS
-- +++++++++++++++++++++++++++++

INSERT INTO ODS_DM_CIUDADES_ESTADOS (DE_CIUDAD, DE_ESTADO, ID_PAIS, FC_INSERT, FC_MODIFICACION)
SELECT distinct 
UPPER(TRIM(PRODUCT_CITY)) CIUDAD,
CASE WHEN LENGTH(TRIM(PRODUCT_STATE)) > 0 THEN UPPER(TRIM(PRODUCT_STATE)) ELSE 'DESCONOCIDO' END ESTADO,
ODS_PAISES.ID_PAIS, now(), now()
FROM STAGE.STG_PRODUCTOS_CRM
INNER JOIN ODS_PAISES ON CASE WHEN LENGTH(TRIM(PRODUCT_COUNTRY))<>0 THEN UPPER(TRIM(PRODUCT_COUNTRY)) ELSE 'DESCONOCIDO' END = ODS_PAISES.DE_PAIS
LEFT JOIN ODS_DM_CIUDADES_ESTADOS ON ODS_DM_CIUDADES_ESTADOS.DE_CIUDAD = UPPER(TRIM(PRODUCT_CITY)) 
AND ODS_DM_CIUDADES_ESTADOS.DE_ESTADO = UPPER(TRIM(PRODUCT_STATE)) 
WHERE LENGTH(TRIM(PRODUCT_CITY))> 0 AND ODS_DM_CIUDADES_ESTADOS.ID_CIUDAD_ESTADO IS NULL;

ANALYZE TABLE ODS_DM_CIUDADES_ESTADOS;

-- AÑADIR CLIENTES QUE NO ESTAN EN ODS_HC_CLIENTES
-- +++++++++++++++++++++++++++++++++++++++++++++++

INSERT INTO ODS_HC_CLIENTES (
ID_CLIENTE,
NOMBRE_CLIENTE,
APELLIDOS_CLIENTE,
NUMDOC_CLIENTE,
ID_SEXO,
ID_DIRECCION_CLIENTE,
TELEFONO_CLIENTE,
EMAIL,
FC_NACIMIENTO,
ID_PROFESION,
ID_COMPANYA,
FC_INSERT,
FC_MODIFICACION)
SELECT DISTINCT 
    999900000 + CUSTOMER_ID,
    'DESCONOCIDO',
    'DESCONOCIDO',
    '99-999-9999',
    99,
    999999,
    9999999999,
    'DESCONOCIDO',
    STR_TO_DATE('31/12/9999','%d/%m/%Y'),
    999,
    999,
    NOW(),
    NOW()
FROM STAGE.STG_PRODUCTOS_CRM SERVICIOS
WHERE CUSTOMER_ID NOT IN (SELECT ID_CLIENTE FROM ODS_HC_CLIENTES)
AND 999900000 + CUSTOMER_ID NOT IN (SELECT ID_CLIENTE FROM ODS_HC_CLIENTES);

ANALYZE TABLE ODS_HC_CLIENTES;

-- AÑADIR DIRECCIONES NUEVAS A LA TABLA ODS_HC_DIRECCIONES
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++

--    Direcciones distintas, no nulas, de la tabla de productos de Stage-Productos

DROP TABLE if exists TMP_DIRECCIONES_DISTINTAS_STAGE;
CREATE TABLE TMP_DIRECCIONES_DISTINTAS_STAGE
SELECT distinct UPPER(TRIM(PRODUCT_ADDRESS)) DIRECCION,
CASE WHEN LENGTH(UPPER(TRIM(PRODUCT_POSTAL_CODE))) <>0 THEN UPPER(TRIM(PRODUCT_POSTAL_CODE)) ELSE 99999 END CP,
UPPER(TRIM(PRODUCT_CITY)) CIUDAD,
UPPER(TRIM(PRODUCT_STATE)) ESTADO,
UPPER(TRIM(PRODUCT_COUNTRY)) PAIS,
ODS_DM_CIUDADES_ESTADOS.ID_CIUDAD_ESTADO
FROM STAGE.STG_PRODUCTOS_CRM PRODUCTOS
INNER JOIN ODS_DM_PAISES ON 
	CASE WHEN length(TRIM(PRODUCTOS.PRODUCT_COUNTRY))> 0 THEN UPPER(TRIM(REPLACE(PRODUCT_COUNTRY, "United States", "US"))) ELSE 'DESCONOCIDO' END = ODS_DM_PAISES.DE_PAIS
INNER JOIN ODS_DM_CIUDADES_ESTADOS ON 
	CASE WHEN length(trim(PRODUCTOS.PRODUCT_CITY))<>0 then TRIM(upper(PRODUCTOS.PRODUCT_CITY)) else 'DESCONOCIDO' end = ODS_DM_CIUDADES_ESTADOS.DE_CIUDAD
AND CASE WHEN length(trim(PRODUCTOS.PRODUCT_STATE))<>0 then TRIM(upper(PRODUCTOS.PRODUCT_STATE)) else 'DESCONOCIDO' end = ODS_DM_CIUDADES_ESTADOS.DE_ESTADO
AND ODS_DM_CIUDADES_ESTADOS.ID_PAIS = ODS_DM_PAISES.ID_PAIS

WHERE LENGTH(PRODUCT_ADDRESS)<>0;

ALTER TABLE `ODS`.`TMP_DIRECCIONES_DISTINTAS_STAGE` 
ADD INDEX `idx_dir_ciu_cp` (`ID_CIUDAD_ESTADO` ASC, `CP` ASC, `DIRECCION` ASC);

ANALYZE TABLE TMP_DIRECCIONES_DISTINTAS_STAGE;


--   Direcciones de Stage-Productos relacionadas con ODS_HC_DIRECCIONES

DROP TABLE if exists TMP_DIRECCIONES_STAGE_ODS;
CREATE TABLE TMP_DIRECCIONES_STAGE_ODS
SELECT DIRECCION, CP, CIUDAD, ESTADO, PAIS, ODS_HC_DIRECCIONES.ID_DIRECCION, TMP_DIRECCIONES_DISTINTAS_STAGE.ID_CIUDAD_ESTADO 
FROM TMP_DIRECCIONES_DISTINTAS_STAGE
LEFT JOIN ODS_HC_DIRECCIONES ON ODS_HC_DIRECCIONES.ID_CIUDAD_ESTADO = TMP_DIRECCIONES_DISTINTAS_STAGE.ID_CIUDAD_ESTADO 
and ODS_HC_DIRECCIONES.DE_CP = CP AND ODS_HC_DIRECCIONES.DE_DIRECCION = DIRECCION ;

ANALYZE TABLE TMP_DIRECCIONES_STAGE_ODS;

--   Insertar direcciones nuevas
insert into ODS_HC_DIRECCIONES (DE_DIRECCION, DE_CP, ID_CIUDAD_ESTADO, FC_INSERT, FC_MODIFICACION)
SELECT DIRECCION,
CP,
ID_CIUDAD_ESTADO,
 now(),
 now()
FROM TMP_DIRECCIONES_STAGE_ODS
WHERE ID_DIRECCION IS NULL;

--   Recalcular la tabla de Stage-Productos relacionadas con ODS_HC_DIRECCIONES depués de añadir las direcciones nuevas

DROP TABLE if exists TMP_DIRECCIONES_STAGE_ODS;
CREATE TABLE TMP_DIRECCIONES_STAGE_ODS
SELECT DIRECCION, CP, CIUDAD, ESTADO, PAIS, ODS_HC_DIRECCIONES.ID_DIRECCION, TMP_DIRECCIONES_DISTINTAS_STAGE.ID_CIUDAD_ESTADO 
FROM TMP_DIRECCIONES_DISTINTAS_STAGE
LEFT JOIN ODS_HC_DIRECCIONES ON ODS_HC_DIRECCIONES.ID_CIUDAD_ESTADO = TMP_DIRECCIONES_DISTINTAS_STAGE.ID_CIUDAD_ESTADO 
and ODS_HC_DIRECCIONES.DE_CP = CP AND ODS_HC_DIRECCIONES.DE_DIRECCION = DIRECCION ;

ANALYZE TABLE TMP_DIRECCIONES_STAGE_ODS;
DROP TABLE IF EXISTS TMP_DIRECCIONES_DISTINTAS_STAGE;

-- POBLAR ODS_HC_SERVICIOS
-- +++++++++++++++++++++++

INSERT INTO ODS_HC_SERVICIOS (ID_SERVICIO,
ID_CLIENTE,
ID_PRODUCTO,
PUNTO_ACCESO,
ID_CANAL,
ID_AGENTE,
FC_INICIO,
FC_INSTALACION,
FC_FIN,
ID_DIRECCION_SERVICIO,
FC_INSERT,
FC_MODIFICACION)
SELECT PRODUCT_ID ID_SERVICIO,
	IFNULL(ID_CLIENTE, 999900000 + CUSTOMER_ID),
    IFNULL(ID_PRODUCTO, 999) ID_PRODUCTO,
    CASE WHEN LENGTH(ACCESS_POINT) > 0 THEN ACCESS_POINT ELSE 99999999999999999999 END PUNTO_ACCESO,
    IFNULL(ID_CANAL, 999) ID_CANAL,
    CASE WHEN LENGTH(TRIM(AGENT_CODE)) > 0 THEN TRIM(AGENT_CODE) ELSE 9999 END ID_AGENTE,
    CASE WHEN LENGTH(TRIM(START_DATE)) > 0 THEN IFNULL(str_to_date(START_DATE, "%d/%m/%Y"), str_to_date("31/12/9999", "%d/%m/%Y"))
		ELSE str_to_date("31/12/9999", "%d/%m/%Y") END FC_INICIO,
    CASE WHEN LENGTH(TRIM(INSTALL_DATE)) > 0 THEN IFNULL(str_to_date(INSTALL_DATE, "%Y-%m-%d %H:%i:%s UTC"), str_to_date("31/12/9999", "%d/%m/%Y"))
		ELSE str_to_date("31/12/9999", "%d/%m/%Y") END FC_INSTALACION,
	CASE WHEN LENGTH(TRIM(END_DATE)) > 0 THEN IFNULL(str_to_date(END_DATE, "%Y-%m-%d %H:%i:%s UTC"), str_to_date("31/12/9999", "%d/%m/%Y")) 
		ELSE str_to_date("31/12/9999", "%d/%m/%Y") END FC_FINALIZACION,
	IFNULL(TEMP_DIR.ID_DIRECCION, 999999),
    NOW(),
    NOW()
FROM STAGE.STG_PRODUCTOS_CRM SERVICIOS
LEFT JOIN ODS_DM_PRODUCTOS ON UPPER(SERVICIOS.PRODUCT_NAME) = ODS_DM_PRODUCTOS.DE_PRODUCTO
LEFT JOIN ODS_DM_CANALES on UPPER(SERVICIOS.CHANNEL) = ODS_DM_CANALES.DE_CANAL
LEFT JOIN ODS_HC_CLIENTES ON ODS_HC_CLIENTES.ID_CLIENTE = SERVICIOS.CUSTOMER_ID
LEFT JOIN TMP_DIRECCIONES_STAGE_ODS TEMP_DIR 
	ON UPPER(TRIM(SERVICIOS.PRODUCT_ADDRESS)) = TEMP_DIR.DIRECCION AND
    UPPER(TRIM(SERVICIOS.PRODUCT_POSTAL_CODE)) = TEMP_DIR.CP AND
    UPPER(TRIM(SERVICIOS.PRODUCT_CITY)) = TEMP_DIR.CIUDAD AND
    UPPER(TRIM(SERVICIOS.PRODUCT_STATE)) = TEMP_DIR.ESTADO AND
    UPPER(TRIM(SERVICIOS.PRODUCT_COUNTRY)) = TEMP_DIR.PAIS;
    
ANALYZE TABLE ODS_HC_SERVICIOS;

DROP TABLE if exists TMP_DIRECCIONES_STAGE_ODS;