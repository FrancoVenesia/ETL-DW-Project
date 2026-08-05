SELECT * 
FROM STG_COM_Customer_Retail cr
JOIN STG_COM_Regions r ON cr.zipcode = r.ZIPCODE
WHERE cr.city != r.CITY

SELECT * 
FROM STG_COM_Customer_Wholesale cw
JOIN STG_COM_Regions r ON cw.zipcode = r.ZIPCODE
WHERE cw.city != r.CITY

