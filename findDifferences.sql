CREATE PROCEDURE CompareDatabases
    @Database1 nvarchar(50),
    @Database2 nvarchar(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Compare tables
    SELECT @Database1 AS DatabaseName,
           t1.name AS TableName,
           'Table' AS ObjectType,
           'Missing in ' + @Database2 AS DifferenceType
    FROM sys.tables t1
    WHERE NOT EXISTS (SELECT 1 FROM sys.tables t2 WHERE t2.name = t1.name AND t2.type = 'U' AND t2.object_id = OBJECT_ID(@Database2 + '.dbo.' + t1.name))
        AND t1.type = 'U'
    UNION ALL
    SELECT @Database2 AS DatabaseName,
           t2.name AS TableName,
           'Table' AS ObjectType,
           'Missing in ' + @Database1 AS DifferenceType
    FROM sys.tables t2
    WHERE NOT EXISTS (SELECT 1 FROM sys.tables t1 WHERE t1.name = t2.name AND t1.type = 'U' AND t1.object_id = OBJECT_ID(@Database1 + '.dbo.' + t2.name))
        AND t2.type = 'U'

    -- Compare views
    UNION ALL
    SELECT @Database1 AS DatabaseName,
           v1.name AS ViewName,
           'View' AS ObjectType,
           'Missing in ' + @Database2 AS DifferenceType
    FROM sys.views v1
    WHERE NOT EXISTS (SELECT 1 FROM sys.views v2 WHERE v2.name = v1.name AND v2.object_id = OBJECT_ID(@Database2 + '.dbo.' + v1.name))
    UNION ALL
    SELECT @Database2 AS DatabaseName,
           v2.name AS ViewName,
           'View' AS ObjectType,
           'Missing in ' + @Database1 AS DifferenceType
    FROM sys.views v2
    WHERE NOT EXISTS (SELECT 1 FROM sys.views v1 WHERE v1.name = v2.name AND v1.object_id = OBJECT_ID(@Database1 + '.dbo.' + v2.name))

    -- Compare stored procedures
    UNION ALL
    SELECT @Database1 AS DatabaseName,
           sp1.name AS ProcedureName,
           'Stored Procedure' AS ObjectType,
           'Missing in ' + @Database2 AS DifferenceType
    FROM sys.procedures sp1
    WHERE NOT EXISTS (SELECT 1 FROM sys.procedures sp2 WHERE sp2.name = sp1.name AND sp2.object_id = OBJECT_ID(@Database2 + '.dbo.' + sp1.name))
    UNION ALL
    SELECT @Database2 AS DatabaseName,
           sp2.name AS ProcedureName,
           'Stored Procedure' AS ObjectType,
           'Missing in ' + @Database1 AS DifferenceType
    FROM sys.procedures sp2
    WHERE NOT EXISTS (SELECT 1 FROM sys.procedures sp1 WHERE sp1.name = sp2.name AND sp1.object_id = OBJECT_ID(@Database1 + '.dbo.' + sp2.name))
END
