/****** Set DB permissions ******/

CREATE USER [user@youraad.com] FROM EXTERNAL PROVIDER;
GO
EXEC sp_addrolemember 'db_datareader', 'user@youraad.com'; 
GO

/*
-- Grant read access to a System Assigned Managed Identity (virtual machine)
*/
CREATE USER [vmname] FROM EXTERNAL PROVIDER;
GO
EXEC sp_addrolemember 'db_datareader', '[vmname]'
GO

/*
-- Grant ability to read SQL Always Encrypted key definitions to a System Assigned Managed Identity (virtual machine)
*/
GRANT VIEW ANY COLUMN MASTER KEY DEFINITION TO "[VMNAME]"
GO
GRANT VIEW ANY COLUMN ENCRYPTION KEY DEFINITION TO "[VMNAME]"
GO
