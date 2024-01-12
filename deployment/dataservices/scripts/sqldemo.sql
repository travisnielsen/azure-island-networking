/****** Set DB permissions ******/

CREATE USER [user@youraad.com] FROM EXTERNAL PROVIDER;
GO
EXEC sp_addrolemember 'db_datareader', 'user@youraad.com'; 
GO
