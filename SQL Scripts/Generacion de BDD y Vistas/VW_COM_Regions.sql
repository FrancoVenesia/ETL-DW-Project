CREATE OR ALTER VIEW dbo.VW_COM_Regions AS
SELECT
	ZIPCODE as zipcode,
	REGION as region,
	STATE as state,
	CITY as city

FROM STAGING_TDC.dbo.STG_COM_Regions