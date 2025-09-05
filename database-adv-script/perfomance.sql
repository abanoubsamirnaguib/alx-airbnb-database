-- Query Performance Optimization
-- File: perfomance.sql

-- =====================================================
-- INITIAL QUERY - Retrieve all bookings with user, property, and payment details
-- =====================================================
-- This query retrieves comprehensive booking information including related data

-- INITIAL QUERY (Before Optimization)
EXPLAIN ANALYZE
SELECT 
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price as booking_total,
    b.status as booking_status,
    b.created_at as booking_created,
    
    -- User details
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    u.phone_number,
    u.role,
    
    -- Property details
    p.property_id,
    p.name as property_name,
    p.description,
    p.location,
    p.pricepernight,
    
    -- Host details
    h.user_id as host_id,
    h.first_name as host_first_name,
    h.last_name as host_last_name,
    h.email as host_email,
    
    -- Payment details
    pay.payment_id,
    pay.amount as payment_amount,
    pay.payment_date,
    pay.payment_method
    
FROM Booking b
INNER JOIN "User" u ON b.user_id = u.user_id
INNER JOIN Property p ON b.property_id = p.property_id
INNER JOIN "User" h ON p.host_id = h.user_id
LEFT JOIN Payment pay ON b.booking_id = pay.booking_id
ORDER BY b.created_at DESC;

-- =====================================================
-- PERFORMANCE ANALYSIS
-- =====================================================
-- Issues identified in the initial query:
-- 1. Retrieving all columns including large text fields (description)
-- 2. Multiple JOINs without filtering conditions
-- 3. No LIMIT clause - could return massive datasets
-- 4. Sorting by created_at without proper indexing consideration
-- 5. Joining "User" table twice (for guest and host)

-- =====================================================
-- OPTIMIZED QUERY VERSION 1 - Selective Column Retrieval
-- =====================================================
-- Optimization: Only select necessary columns, avoid large text fields

EXPLAIN ANALYZE
SELECT 
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    
    -- Essential user details only
    u.first_name || ' ' || u.last_name as guest_name,
    u.email as guest_email,
    
    -- Essential property details only
    p.name as property_name,
    p.location,
    p.pricepernight,
    
    -- Essential host details only
    h.first_name || ' ' || h.last_name as host_name,
    
    -- Payment summary
    pay.amount as payment_amount,
    pay.payment_method
    
FROM Booking b
INNER JOIN "User" u ON b.user_id = u.user_id
INNER JOIN Property p ON b.property_id = p.property_id
INNER JOIN "User" h ON p.host_id = h.user_id
LEFT JOIN Payment pay ON b.booking_id = pay.booking_id
ORDER BY b.created_at DESC
LIMIT 100;

-- =====================================================
-- OPTIMIZED QUERY VERSION 2 - With Filtering and Indexing
-- =====================================================
-- Optimization: Add WHERE conditions to reduce dataset size

EXPLAIN ANALYZE
SELECT 
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    u.first_name || ' ' || u.last_name as guest_name,
    p.name as property_name,
    p.location,
    h.first_name || ' ' || h.last_name as host_name,
    pay.amount as payment_amount,
    pay.payment_method
    
FROM Booking b
INNER JOIN "User" u ON b.user_id = u.user_id
INNER JOIN Property p ON b.property_id = p.property_id
INNER JOIN "User" h ON p.host_id = h.user_id
LEFT JOIN Payment pay ON b.booking_id = pay.booking_id

WHERE b.created_at >= CURRENT_DATE - INTERVAL '1 year'  -- Filter recent bookings
AND b.status IN ('confirmed', 'pending')                -- Filter active bookings
ORDER BY b.created_at DESC
LIMIT 50;

-- =====================================================
-- OPTIMIZED QUERY VERSION 3 - Avoid Duplicate User Join
-- =====================================================
-- Optimization: Use subquery or CTE to avoid joining User table twice

EXPLAIN ANALYZE
WITH booking_details AS (
    SELECT 
        b.booking_id,
        b.user_id,
        b.property_id,
        b.start_date,
        b.end_date,
        b.total_price,
        b.status,
        b.created_at
    FROM Booking b
    WHERE b.created_at >= CURRENT_DATE - INTERVAL '1 year'
    AND b.status IN ('confirmed', 'pending')
),
user_info AS (
    SELECT user_id, first_name, last_name, email, role FROM "User"
)
SELECT 
    bd.booking_id,
    bd.start_date,
    bd.end_date,
    bd.total_price,
    bd.status,
    
    -- Guest details
    guest.first_name || ' ' || guest.last_name as guest_name,
    guest.email as guest_email,
    
    -- Property details
    p.name as property_name,
    p.location,
    p.pricepernight,
    
    -- Host details
    host.first_name || ' ' || host.last_name as host_name,
    
    -- Payment details
    pay.amount as payment_amount,
    pay.payment_method
    
FROM booking_details bd
INNER JOIN user_info guest ON bd.user_id = guest.user_id
INNER JOIN Property p ON bd.property_id = p.property_id
INNER JOIN user_info host ON p.host_id = host.user_id
LEFT JOIN Payment pay ON bd.booking_id = pay.booking_id
ORDER BY bd.created_at DESC
LIMIT 50;

-- =====================================================
-- OPTIMIZED QUERY VERSION 4 - Pagination Support
-- =====================================================
-- Optimization: Add pagination for better performance in applications

EXPLAIN ANALYZE
SELECT 
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    b.created_at,
    
    -- Guest details
    u.first_name || ' ' || u.last_name as guest_name,
    u.email as guest_email,
    
    -- Property details
    p.name as property_name,
    p.location,
    
    -- Host details
    h.first_name || ' ' || h.last_name as host_name,
    
    -- Payment summary
    CASE 
        WHEN pay.payment_id IS NOT NULL THEN 'Paid'
        ELSE 'Pending'
    END as payment_status,
    pay.amount as payment_amount
    
FROM Booking b
INNER JOIN "User" u ON b.user_id = u.user_id
INNER JOIN Property p ON b.property_id = p.property_id
INNER JOIN "User" h ON p.host_id = h.user_id
LEFT JOIN Payment pay ON b.booking_id = pay.booking_id

WHERE b.created_at >= CURRENT_DATE - INTERVAL '6 months'
AND b.status IN ('confirmed', 'pending')

ORDER BY b.created_at DESC
LIMIT 20 OFFSET 0;  -- Pagination: page 1, 20 records per page

-- =====================================================
-- OPTIMIZED QUERY VERSION 5 - Covering Index Approach
-- =====================================================
-- Optimization: Design query to use covering indexes effectively

EXPLAIN ANALYZE
SELECT 
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    
    -- Use indexed columns for JOINs
    u.first_name,
    u.last_name,
    u.email,
    
    p.name as property_name,
    p.location,
    
    pay.amount as payment_amount,
    pay.payment_method
    
FROM Booking b
INNER JOIN "User" u ON b.user_id = u.user_id
INNER JOIN Property p ON b.property_id = p.property_id
LEFT JOIN Payment pay ON b.booking_id = pay.booking_id

WHERE b.start_date >= '2024-01-01'
AND b.start_date <= '2024-12-31'
AND b.status = 'confirmed'

ORDER BY b.start_date, b.booking_id  -- Use compound sort for better index usage
LIMIT 25;

-- =====================================================
-- PERFORMANCE COMPARISON QUERIES
-- =====================================================
-- Run these queries to compare execution times

-- Test 1: Count total rows without optimization
EXPLAIN ANALYZE
SELECT COUNT(*) 
FROM Booking b
INNER JOIN "User" u ON b.user_id = u.user_id
INNER JOIN Property p ON b.property_id = p.property_id
INNER JOIN "User" h ON p.host_id = h.user_id
LEFT JOIN Payment pay ON b.booking_id = pay.booking_id;

-- Test 2: Count with filtering
EXPLAIN ANALYZE
SELECT COUNT(*) 
FROM Booking b
WHERE b.created_at >= CURRENT_DATE - INTERVAL '1 year'
AND b.status IN ('confirmed', 'pending');

-- Test 3: Check index usage for date range queries
EXPLAIN ANALYZE
SELECT booking_id, start_date, end_date, total_price
FROM Booking 
WHERE start_date >= '2024-01-01' 
AND start_date <= '2024-12-31'
ORDER BY start_date
LIMIT 100;

-- =====================================================
-- RECOMMENDED INDEXES FOR OPTIMAL PERFORMANCE
-- =====================================================
-- These indexes should be created for optimal performance of the above queries

-- CREATE INDEX idx_booking_created_status ON Booking (created_at, status);
-- CREATE INDEX idx_booking_start_date_status ON Booking (start_date, status);
-- CREATE INDEX idx_booking_date_range_status ON Booking (start_date, end_date, status);
-- CREATE INDEX idx_user_name_email ON "User" (first_name, last_name, email);
-- CREATE INDEX idx_property_name_location ON Property (name, location);

-- =====================================================
-- MONITORING AND ANALYSIS COMMANDS
-- =====================================================
-- Use these to monitor query performance

-- Check current query execution statistics
SELECT query, calls, total_time, mean_time, rows
FROM pg_stat_statements
WHERE query LIKE '%Booking%'
ORDER BY total_time DESC
LIMIT 5;

-- Analyze table statistics
ANALYZE Booking;
ANALYZE "User";
ANALYZE Property;
ANALYZE Payment;
