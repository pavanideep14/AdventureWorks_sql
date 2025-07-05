-- ✅ STEP 1: Use your database
USE SCD_Demo;
GO

-- ✅ STEP 2: Drop existing tables
IF OBJECT_ID('stg_customer') IS NOT NULL DROP TABLE stg_customer;
IF OBJECT_ID('dim_customer') IS NOT NULL DROP TABLE dim_customer;
IF OBJECT_ID('dim_customer_current') IS NOT NULL DROP TABLE dim_customer_current;
IF OBJECT_ID('dim_customer_history') IS NOT NULL DROP TABLE dim_customer_history;
GO

-- ✅ STEP 3: Create tables

-- Staging table
CREATE TABLE stg_customer (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    customer_address VARCHAR(255)
);

-- Dimension table (used in Type 1, 2, 3, 6)
CREATE TABLE dim_customer (
    customer_sk INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    customer_name VARCHAR(100),
    customer_address VARCHAR(255),
    prev_customer_address VARCHAR(255),
    start_date DATETIME,
    end_date DATETIME,
    current_flag BIT,
    version INT
);

-- For Type 4
CREATE TABLE dim_customer_current (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    customer_address VARCHAR(255)
);

CREATE TABLE dim_customer_history (
    history_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    customer_name VARCHAR(100),
    customer_address VARCHAR(255),
    archived_at DATETIME
);
GO

-- ✅ STEP 4: Insert initial data into staging
INSERT INTO stg_customer (customer_id, customer_name, customer_address)
VALUES 
(1, 'Alice', 'Delhi'),
(2, 'Bob', 'Mumbai'),
(3, 'Charlie', 'Bangalore');
GO

-- ✅ STEP 5: SCD Type 0 (No change allowed) — Logic only
-- You do NOT allow changes. So during merge/update, you skip any update if data exists.
-- Typically enforced by NOT including UPDATE clause in MERGE.

-- ✅ STEP 6: SCD Type 1 (Overwrite)
CREATE OR ALTER PROCEDURE scd_type_1
AS
BEGIN
    MERGE dim_customer AS target
    USING stg_customer AS source
    ON target.customer_id = source.customer_id
    WHEN MATCHED THEN
        UPDATE SET
            target.customer_name = source.customer_name,
            target.customer_address = source.customer_address,
            target.start_date = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (customer_id, customer_name, customer_address, prev_customer_address,
                start_date, end_date, current_flag, version)
        VALUES (source.customer_id, source.customer_name, source.customer_address, NULL,
                GETDATE(), NULL, 1, 1);
END;
GO

-- ✅ STEP 7: SCD Type 2 (Track full history)
CREATE OR ALTER PROCEDURE scd_type_2
AS
BEGIN
    DECLARE @now DATETIME = GETDATE();

    -- Expire old record
    UPDATE dim_customer
    SET end_date = @now, current_flag = 0
    FROM dim_customer d
    JOIN stg_customer s ON d.customer_id = s.customer_id
    WHERE d.current_flag = 1 AND (
        d.customer_name <> s.customer_name OR
        d.customer_address <> s.customer_address
    );

    -- Insert new version
    INSERT INTO dim_customer (customer_id, customer_name, customer_address,
        prev_customer_address, start_date, end_date, current_flag, version)
    SELECT
        s.customer_id, s.customer_name, s.customer_address,
        NULL, @now, NULL, 1,
        ISNULL(d.version, 0) + 1
    FROM stg_customer s
    LEFT JOIN dim_customer d ON s.customer_id = d.customer_id AND d.current_flag = 1
    WHERE d.customer_id IS NULL OR
        d.customer_name <> s.customer_name OR
        d.customer_address <> s.customer_address;
END;
GO

-- ✅ STEP 8: SCD Type 3 (Store previous value)
CREATE OR ALTER PROCEDURE scd_type_3
AS
BEGIN
    MERGE dim_customer AS target
    USING stg_customer AS source
    ON target.customer_id = source.customer_id
    WHEN MATCHED AND target.customer_address <> source.customer_address THEN
        UPDATE SET
            target.prev_customer_address = target.customer_address,
            target.customer_address = source.customer_address,
            target.customer_name = source.customer_name
    WHEN NOT MATCHED THEN
        INSERT (customer_id, customer_name, customer_address, prev_customer_address,
                start_date, end_date, current_flag, version)
        VALUES (source.customer_id, source.customer_name, source.customer_address,
                NULL, GETDATE(), NULL, 1, 1);
END;
GO

-- ✅ STEP 9: SCD Type 4 (Current + History)
CREATE OR ALTER PROCEDURE scd_type_4
AS
BEGIN
    DECLARE @now DATETIME = GETDATE();

    -- Archive old to history
    INSERT INTO dim_customer_history (customer_id, customer_name, customer_address, archived_at)
    SELECT c.customer_id, c.customer_name, c.customer_address, @now
    FROM dim_customer_current c
    JOIN stg_customer s ON c.customer_id = s.customer_id
    WHERE c.customer_name <> s.customer_name OR c.customer_address <> s.customer_address;

    -- Update current
    MERGE dim_customer_current AS target
    USING stg_customer AS source
    ON target.customer_id = source.customer_id
    WHEN MATCHED THEN
        UPDATE SET
            target.customer_name = source.customer_name,
            target.customer_address = source.customer_address
    WHEN NOT MATCHED THEN
        INSERT (customer_id, customer_name, customer_address)
        VALUES (source.customer_id, source.customer_name, source.customer_address);
END;
GO

-- ✅ STEP 10: SCD Type 6 (Hybrid: 1 + 2 + 3)
CREATE OR ALTER PROCEDURE scd_type_6
AS
BEGIN
    DECLARE @now DATETIME = GETDATE();

    -- Type 2 expiration
    UPDATE dim_customer
    SET end_date = @now, current_flag = 0
    FROM dim_customer d
    JOIN stg_customer s ON d.customer_id = s.customer_id
    WHERE d.current_flag = 1 AND d.customer_address <> s.customer_address;

    -- Insert new version (type 2 + 3)
    INSERT INTO dim_customer (customer_id, customer_name, customer_address,
        prev_customer_address, start_date, end_date, current_flag, version)
    SELECT
        s.customer_id, s.customer_name, s.customer_address,
        d.customer_address, @now, NULL, 1,
        ISNULL(d.version, 0) + 1
    FROM stg_customer s
    LEFT JOIN dim_customer d ON s.customer_id = d.customer_id AND d.current_flag = 1
    WHERE d.customer_address <> s.customer_address OR d.customer_id IS NULL;

    -- Type 1 update for name
    UPDATE dim_customer
    SET customer_name = s.customer_name
    FROM dim_customer d
    JOIN stg_customer s ON d.customer_id = s.customer_id
    WHERE d.current_flag = 1 AND d.customer_name <> s.customer_name;
END;
GO

-- ✅ STEP 11: Execute the stored procedure you want to test
EXEC scd_type_1;  -- or EXEC scd_type_2, etc.
GO

-- ✅ STEP 12: View result (for dim_customer or type 4)
SELECT * FROM dim_customer;
SELECT * FROM dim_customer_current;
SELECT * FROM dim_customer_history;
