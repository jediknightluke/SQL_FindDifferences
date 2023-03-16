-- Set the database names
USE first_database;
DECLARE @first_database_name AS VARCHAR(50) = DB_NAME();

USE second_database;
DECLARE @second_database_name AS VARCHAR(50) = DB_NAME();

-- Create temporary tables to store the results
CREATE TABLE #differences (table_name VARCHAR(100), column_name VARCHAR(100), difference VARCHAR(100));

-- Find the tables that exist in both databases
SELECT TABLE_NAME
INTO #common_tables
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
AND TABLE_NAME IN (
    SELECT TABLE_NAME
    FROM first_database.INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = 'BASE TABLE'
    AND TABLE_NAME IN (
        SELECT TABLE_NAME
        FROM second_database.INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE'
    )
);

-- Loop through the common tables and compare the columns
DECLARE @table_name AS VARCHAR(100);

DECLARE common_tables_cursor CURSOR FOR
SELECT table_name FROM #common_tables;

OPEN common_tables_cursor;

FETCH NEXT FROM common_tables_cursor
INTO @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO #differences
    SELECT
        @table_name,
        c1.COLUMN_NAME,
        'Data Type Mismatch'
    FROM first_database.INFORMATION_SCHEMA.COLUMNS c1
    LEFT JOIN second_database.INFORMATION_SCHEMA.COLUMNS c2
    ON c1.TABLE_NAME = c2.TABLE_NAME
    AND c1.COLUMN_NAME = c2.COLUMN_NAME
    WHERE c1.TABLE_NAME = @table_name
    AND c2.COLUMN_NAME IS NULL
    AND c1.DATA_TYPE <> 'timestamp';

    INSERT INTO #differences
    SELECT
        @table_name,
        c2.COLUMN_NAME,
        'Data Type Mismatch'
    FROM first_database.INFORMATION_SCHEMA.COLUMNS c1
    RIGHT JOIN second_database.INFORMATION_SCHEMA.COLUMNS c2
    ON c1.TABLE_NAME = c2.TABLE_NAME
    AND c1.COLUMN_NAME = c2.COLUMN_NAME
    WHERE c2.TABLE_NAME = @table_name
    AND c1.COLUMN_NAME IS NULL
    AND c2.DATA_TYPE <> 'timestamp';

    FETCH NEXT FROM common_tables_cursor
    INTO @table_name;
END;

CLOSE common_tables_cursor;
DEALLOCATE common_tables_cursor;

-- Select the results
SELECT * FROM #differences;

-- Clean up the temporary tables
DROP TABLE #common_tables;
DROP TABLE #differences;
