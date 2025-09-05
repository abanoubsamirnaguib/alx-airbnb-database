-- Table Partitioning Implementation for Performance Optimization
-- File: partitioning.sql

-- =====================================================
-- SCENARIO: Large Booking table with slow query performance
-- SOLUTION: Implement partitioning based on start_date column
-- =====================================================

-- =====================================================
-- STEP 1: CREATE PARTITIONED BOOKING TABLE
-- =====================================================
-- First, we need to create a new partitioned version of the Booking table

-- Create the main partitioned table
CREATE TABLE Booking_Partitioned (
    booking_id UUID DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL,
    user_id UUID NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(10) NOT NULL CHECK (status IN ('pending', 'confirmed', 'canceled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_booking_partitioned_property FOREIGN KEY (property_id) REFERENCES Property(property_id),
    CONSTRAINT fk_booking_partitioned_user FOREIGN KEY (user_id) REFERENCES "User"(user_id)
) PARTITION BY RANGE (start_date);

-- =====================================================
-- STEP 2: CREATE PARTITIONS BY DATE RANGES
-- =====================================================
-- Create quarterly partitions for better management

-- 2023 Partitions
CREATE TABLE Booking_2023_Q1 PARTITION OF Booking_Partitioned
    FOR VALUES FROM ('2023-01-01') TO ('2023-04-01');

CREATE TABLE Booking_2023_Q2 PARTITION OF Booking_Partitioned
    FOR VALUES FROM ('2023-04-01') TO ('2023-07-01');

CREATE TABLE Booking_2023_Q3 PARTITION OF Booking_Partitioned
    FOR VALUES FROM ('2023-07-01') TO ('2023-10-01');

CREATE TABLE Booking_2023_Q4 PARTITION OF Booking_Partitioned
    FOR VALUES FROM ('2023-10-01') TO ('2024-01-01');

-- 2024 Partitions
CREATE TABLE Booking_2024_Q1 PARTITION OF Booking_Partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE Booking_2024_Q2 PARTITION OF Booking_Partitioned
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

CREATE TABLE Booking_2024_Q3 PARTITION OF Booking_Partitioned
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');

CREATE TABLE Booking_2024_Q4 PARTITION OF Booking_Partitioned
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

-- 2025 Partitions
CREATE TABLE Booking_2025_Q1 PARTITION OF Booking_Partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');

CREATE TABLE Booking_2025_Q2 PARTITION OF Booking_Partitioned
    FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');

CREATE TABLE Booking_2025_Q3 PARTITION OF Booking_Partitioned
    FOR VALUES FROM ('2025-07-01') TO ('2025-10-01');

CREATE TABLE Booking_2025_Q4 PARTITION OF Booking_Partitioned
    FOR VALUES FROM ('2025-10-01') TO ('2026-01-01');

-- Default partition for future dates
CREATE TABLE Booking_Default PARTITION OF Booking_Partitioned DEFAULT;

-- =====================================================
-- STEP 3: CREATE INDEXES ON PARTITIONED TABLE
-- =====================================================
-- Create indexes on the main table (will be inherited by partitions)

CREATE INDEX idx_booking_partitioned_user_id ON Booking_Partitioned (user_id);
CREATE INDEX idx_booking_partitioned_property_id ON Booking_Partitioned (property_id);
CREATE INDEX idx_booking_partitioned_status ON Booking_Partitioned (status);
CREATE INDEX idx_booking_partitioned_start_date ON Booking_Partitioned (start_date);
CREATE INDEX idx_booking_partitioned_end_date ON Booking_Partitioned (end_date);
CREATE INDEX idx_booking_partitioned_created_at ON Booking_Partitioned (created_at);

-- Composite indexes for common query patterns
CREATE INDEX idx_booking_partitioned_date_range ON Booking_Partitioned (start_date, end_date);
CREATE INDEX idx_booking_partitioned_user_status ON Booking_Partitioned (user_id, status);
CREATE INDEX idx_booking_partitioned_property_status ON Booking_Partitioned (property_id, status);

-- =====================================================
-- STEP 4: MIGRATE DATA FROM ORIGINAL TABLE (if exists)
-- =====================================================
-- Insert sample data for testing (since we don't have actual data)

-- Sample data insertion for testing partitioning
INSERT INTO Booking_Partitioned (property_id, user_id, start_date, end_date, total_price, status, created_at)
SELECT 
    (ARRAY[
        '123e4567-e89b-12d3-a456-426614174001',
        '123e4567-e89b-12d3-a456-426614174002',
        '123e4567-e89b-12d3-a456-426614174003'
    ])[floor(random() * 3 + 1)::int]::uuid,
    (ARRAY[
        '123e4567-e89b-12d3-a456-426614174004',
        '123e4567-e89b-12d3-a456-426614174005',
        '123e4567-e89b-12d3-a456-426614174006'
    ])[floor(random() * 3 + 1)::int]::uuid,
    '2024-01-01'::date + (random() * 365)::int,
    '2024-01-01'::date + (random() * 365)::int + interval '3 days',
    (random() * 500 + 100)::decimal(10,2),
    (ARRAY['pending', 'confirmed', 'canceled'])[floor(random() * 3 + 1)::int],
    '2024-01-01'::timestamp + (random() * interval '365 days')
FROM generate_series(1, 10000);  -- Generate 10,000 test records

-- =====================================================
-- STEP 5: PERFORMANCE TESTING - NON-PARTITIONED QUERIES
-- =====================================================
-- Test queries on original table structure (simulated)

-- Simulate non-partitioned table performance
CREATE TABLE Booking_NonPartitioned AS 
SELECT * FROM Booking_Partitioned;

-- Test 1: Date range query on non-partitioned table
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT booking_id, start_date, end_date, total_price, status
FROM Booking_NonPartitioned
WHERE start_date >= '2024-01-01' 
AND start_date <= '2024-03-31'
ORDER BY start_date;

-- Test 2: User bookings in date range on non-partitioned table
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT booking_id, start_date, end_date, total_price
FROM Booking_NonPartitioned
WHERE user_id = '123e4567-e89b-12d3-a456-426614174004'
AND start_date >= '2024-06-01'
AND start_date <= '2024-08-31'
ORDER BY start_date;

-- Test 3: Monthly booking count on non-partitioned table
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    DATE_TRUNC('month', start_date) as month,
    COUNT(*) as booking_count,
    SUM(total_price) as total_revenue
FROM Booking_NonPartitioned
WHERE start_date >= '2024-01-01'
AND start_date <= '2024-12-31'
AND status = 'confirmed'
GROUP BY DATE_TRUNC('month', start_date)
ORDER BY month;

-- =====================================================
-- STEP 6: PERFORMANCE TESTING - PARTITIONED QUERIES
-- =====================================================
-- Test the same queries on partitioned table

-- Test 1: Date range query on partitioned table
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT booking_id, start_date, end_date, total_price, status
FROM Booking_Partitioned
WHERE start_date >= '2024-01-01' 
AND start_date <= '2024-03-31'
ORDER BY start_date;

-- Test 2: User bookings in date range on partitioned table
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT booking_id, start_date, end_date, total_price
FROM Booking_Partitioned
WHERE user_id = '123e4567-e89b-12d3-a456-426614174004'
AND start_date >= '2024-06-01'
AND start_date <= '2024-08-31'
ORDER BY start_date;

-- Test 3: Monthly booking count on partitioned table
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    DATE_TRUNC('month', start_date) as month,
    COUNT(*) as booking_count,
    SUM(total_price) as total_revenue
FROM Booking_Partitioned
WHERE start_date >= '2024-01-01'
AND start_date <= '2024-12-31'
AND status = 'confirmed'
GROUP BY DATE_TRUNC('month', start_date)
ORDER BY month;

-- =====================================================
-- STEP 7: PARTITION PRUNING DEMONSTRATION
-- =====================================================
-- Show how partition pruning works

-- Query that hits single partition
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT COUNT(*)
FROM Booking_Partitioned
WHERE start_date >= '2024-01-01' AND start_date < '2024-04-01';

-- Query that hits multiple partitions
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT COUNT(*)
FROM Booking_Partitioned
WHERE start_date >= '2024-03-15' AND start_date < '2024-07-15';

-- Query that hits all partitions (should be avoided)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT COUNT(*)
FROM Booking_Partitioned
WHERE status = 'confirmed';

-- =====================================================
-- STEP 8: PARTITION MAINTENANCE QUERIES
-- =====================================================
-- Queries for monitoring and maintaining partitions

-- Check partition sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE tablename LIKE 'booking_%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check partition constraint information
SELECT 
    schemaname,
    tablename,
    pg_get_expr(c.relpartbound, c.oid) as partition_bounds
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_tables t ON t.tablename = c.relname AND t.schemaname = n.nspname
WHERE c.relispartition = true
AND tablename LIKE 'booking_%'
ORDER BY tablename;

-- Check which partitions are being accessed
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch
FROM pg_stat_user_tables
WHERE tablename LIKE 'booking_%'
ORDER BY tablename;

-- =====================================================
-- STEP 9: AUTOMATED PARTITION MANAGEMENT
-- =====================================================
-- Function to create new partitions automatically

CREATE OR REPLACE FUNCTION create_quarterly_partition(start_date DATE)
RETURNS void AS $$
DECLARE
    partition_name TEXT;
    end_date DATE;
BEGIN
    -- Calculate partition name and end date
    partition_name := 'Booking_' || TO_CHAR(start_date, 'YYYY') || '_Q' || 
                     EXTRACT(QUARTER FROM start_date);
    end_date := start_date + INTERVAL '3 months';
    
    -- Create the partition
    EXECUTE format('CREATE TABLE %I PARTITION OF Booking_Partitioned 
                   FOR VALUES FROM (%L) TO (%L)',
                   partition_name, start_date, end_date);
    
    RAISE NOTICE 'Created partition % for dates % to %', 
                 partition_name, start_date, end_date;
END;
$$ LANGUAGE plpgsql;

-- Example: Create partition for Q1 2026
-- SELECT create_quarterly_partition('2026-01-01');

-- =====================================================
-- STEP 10: PERFORMANCE COMPARISON SUMMARY
-- =====================================================
-- Summary queries to compare performance

-- Compare table sizes
SELECT 
    'Non-Partitioned' as table_type,
    pg_size_pretty(pg_total_relation_size('Booking_NonPartitioned')) as total_size
UNION ALL
SELECT 
    'Partitioned' as table_type,
    pg_size_pretty(pg_total_relation_size('Booking_Partitioned')) as total_size;

-- Test partition elimination effectiveness
EXPLAIN (FORMAT JSON)
SELECT booking_id, start_date, total_price
FROM Booking_Partitioned
WHERE start_date = '2024-05-15';

-- Cleanup test tables (uncomment when testing is complete)
-- DROP TABLE IF EXISTS Booking_NonPartitioned;
-- DROP TABLE IF EXISTS Booking_Partitioned CASCADE;
