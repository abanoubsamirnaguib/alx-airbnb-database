-- Database Performance Optimization - Indexes
-- File: database_index.sql

-- =====================================================
-- HIGH-USAGE COLUMN ANALYSIS
-- =====================================================
-- Based on our queries in joins_queries.sql, subqueries.sql, and aggregations_and_window_functions.sql
-- The following columns are frequently used in WHERE, JOIN, and ORDER BY clauses:

-- USER TABLE:
-- - user_id: Primary key, frequently used in JOINs
-- - email: Used in WHERE clauses for user lookup
-- - role: Used in WHERE clauses for filtering by user type
-- - created_at: Used in ORDER BY clauses

-- BOOKING TABLE:
-- - booking_id: Primary key
-- - user_id: Foreign key, heavily used in JOINs
-- - property_id: Foreign key, heavily used in JOINs
-- - start_date, end_date: Used in WHERE clauses for date range queries
-- - status: Used in WHERE clauses for filtering bookings
-- - created_at: Used in ORDER BY clauses

-- PROPERTY TABLE:
-- - property_id: Primary key
-- - host_id: Foreign key, used in JOINs
-- - location: Used in WHERE clauses for location-based searches
-- - pricepernight: Used in WHERE clauses for price filtering and ORDER BY
-- - created_at: Used in ORDER BY clauses

-- REVIEW TABLE:
-- - review_id: Primary key
-- - property_id: Foreign key, used in JOINs and GROUP BY
-- - user_id: Foreign key, used in JOINs
-- - rating: Used in WHERE clauses and aggregation functions
-- - created_at: Used in ORDER BY clauses

-- =====================================================
-- EXISTING INDEXES (from schema.sql)
-- =====================================================
-- These indexes already exist in the schema:
-- - idx_user_email ON "User" (email)
-- - idx_property_host_id ON Property (host_id)
-- - idx_property_property_id ON Property (property_id)
-- - idx_booking_property_id ON Booking (property_id)
-- - idx_booking_user_id ON Booking (user_id)
-- - idx_booking_booking_id ON Booking (booking_id)
-- - idx_payment_booking_id ON Payment (booking_id)
-- - idx_payment_payment_id ON Payment (payment_id)
-- - idx_review_property_id ON Review (property_id)
-- - idx_review_user_id ON Review (user_id)
-- - idx_review_review_id ON Review (review_id)
-- - idx_message_sender_id ON Message (sender_id)
-- - idx_message_recipient_id ON Message (recipient_id)
-- - idx_message_message_id ON Message (message_id)

-- =====================================================
-- ADDITIONAL PERFORMANCE INDEXES
-- =====================================================
-- Based on query analysis, these additional indexes will improve performance:

-- 1. User table indexes for filtering and sorting
CREATE INDEX idx_user_role ON "User" (role);
CREATE INDEX idx_user_created_at ON "User" (created_at);
CREATE INDEX idx_user_role_created_at ON "User" (role, created_at);

-- 2. Booking table indexes for date range queries and status filtering
CREATE INDEX idx_booking_start_date ON Booking (start_date);
CREATE INDEX idx_booking_end_date ON Booking (end_date);
CREATE INDEX idx_booking_status ON Booking (status);
CREATE INDEX idx_booking_created_at ON Booking (created_at);
CREATE INDEX idx_booking_date_range ON Booking (start_date, end_date);
CREATE INDEX idx_booking_user_status ON Booking (user_id, status);
CREATE INDEX idx_booking_property_status ON Booking (property_id, status);

-- 3. Property table indexes for location and price searches
CREATE INDEX idx_property_location ON Property (location);
CREATE INDEX idx_property_pricepernight ON Property (pricepernight);
CREATE INDEX idx_property_created_at ON Property (created_at);
CREATE INDEX idx_property_location_price ON Property (location, pricepernight);
CREATE INDEX idx_property_host_created ON Property (host_id, created_at);

-- 4. Review table indexes for rating queries and aggregations
CREATE INDEX idx_review_rating ON Review (rating);
CREATE INDEX idx_review_created_at ON Review (created_at);
CREATE INDEX idx_review_property_rating ON Review (property_id, rating);
CREATE INDEX idx_review_property_created ON Review (property_id, created_at);

-- 5. Composite indexes for complex queries
CREATE INDEX idx_booking_user_dates ON Booking (user_id, start_date, end_date);
CREATE INDEX idx_property_host_price ON Property (host_id, pricepernight);
CREATE INDEX idx_review_rating_created ON Review (rating, created_at);

-- =====================================================
-- PARTIAL INDEXES FOR SPECIFIC USE CASES
-- =====================================================
-- These indexes target specific query patterns:

-- Index for active bookings only
CREATE INDEX idx_booking_active ON Booking (property_id, start_date) 
WHERE status IN ('confirmed', 'pending');

-- Index for highly rated properties
CREATE INDEX idx_review_high_rating ON Review (property_id) 
WHERE rating >= 4;

-- Index for recent bookings
CREATE INDEX idx_booking_recent ON Booking (user_id, created_at) 
WHERE created_at >= CURRENT_DATE - INTERVAL '1 year';

-- =====================================================
-- TEXT SEARCH INDEXES (if using full-text search)
-- =====================================================
-- For property name and description searches
CREATE INDEX idx_property_name_gin ON Property USING gin(to_tsvector('english', name));
CREATE INDEX idx_property_description_gin ON Property USING gin(to_tsvector('english', description));

-- For review comment searches
CREATE INDEX idx_review_comment_gin ON Review USING gin(to_tsvector('english', comment));

-- =====================================================
-- PERFORMANCE TESTING - BEFORE AND AFTER INDEXES
-- =====================================================
-- Run these queries BEFORE creating the indexes to establish baseline performance

-- Test Query 1: Booking search with date range and status
EXPLAIN ANALYZE
SELECT b.booking_id, b.start_date, b.end_date, b.total_price, b.status,
       u.first_name, u.last_name, u.email
FROM Booking b
INNER JOIN "User" u ON b.user_id = u.user_id
WHERE b.start_date >= '2024-01-01' 
AND b.end_date <= '2024-12-31'
AND b.status = 'confirmed'
ORDER BY b.start_date;

-- Test Query 2: Properties by location and price range
EXPLAIN ANALYZE
SELECT p.property_id, p.name, p.location, p.pricepernight,
       h.first_name || ' ' || h.last_name AS host_name
FROM Property p
INNER JOIN "User" h ON p.host_id = h.user_id
WHERE p.location LIKE '%New York%' 
AND p.pricepernight BETWEEN 100 AND 300
ORDER BY p.pricepernight;

-- Test Query 3: Properties with high average ratings
EXPLAIN ANALYZE
SELECT p.property_id, p.name, p.location,
       AVG(r.rating) as avg_rating,
       COUNT(r.review_id) as review_count
FROM Property p
INNER JOIN Review r ON p.property_id = r.property_id
GROUP BY p.property_id, p.name, p.location
HAVING AVG(r.rating) > 4.0
ORDER BY avg_rating DESC;

-- Test Query 4: User booking statistics by role
EXPLAIN ANALYZE
SELECT u.user_id, u.first_name, u.last_name, u.role,
       COUNT(b.booking_id) as total_bookings,
       SUM(b.total_price) as total_spent
FROM "User" u 
LEFT JOIN Booking b ON u.user_id = b.user_id 
WHERE u.role = 'guest'
AND u.created_at >= '2023-01-01'
GROUP BY u.user_id, u.first_name, u.last_name, u.role
ORDER BY total_bookings DESC;

-- Test Query 5: Recent bookings with property details
EXPLAIN ANALYZE
SELECT b.booking_id, b.start_date, b.status,
       p.name as property_name, p.location,
       u.first_name || ' ' || u.last_name as guest_name
FROM Booking b
INNER JOIN Property p ON b.property_id = p.property_id
INNER JOIN "User" u ON b.user_id = u.user_id
WHERE b.created_at >= CURRENT_DATE - INTERVAL '30 days'
AND b.status IN ('confirmed', 'pending')
ORDER BY b.created_at DESC;

-- Test Query 6: Host performance analysis
EXPLAIN ANALYZE
SELECT h.user_id, h.first_name, h.last_name,
       COUNT(DISTINCT p.property_id) as properties_count,
       COUNT(b.booking_id) as total_bookings,
       AVG(r.rating) as avg_rating
FROM "User" h
INNER JOIN Property p ON h.user_id = p.host_id
LEFT JOIN Booking b ON p.property_id = b.property_id
LEFT JOIN Review r ON p.property_id = r.property_id
WHERE h.role = 'host'
GROUP BY h.user_id, h.first_name, h.last_name
HAVING COUNT(b.booking_id) > 5
ORDER BY total_bookings DESC;

-- =====================================================
-- INSTRUCTIONS FOR PERFORMANCE TESTING
-- =====================================================
-- 1. Run the EXPLAIN ANALYZE queries above BEFORE creating indexes
-- 2. Note the execution times and query plans
-- 3. Create the indexes using the CREATE INDEX commands above
-- 4. Run the SAME EXPLAIN ANALYZE queries AFTER creating indexes
-- 5. Compare the results:
--    - Execution time should be significantly reduced
--    - Scan types should change from Seq Scan to Index Scan
--    - Cost estimates should be lower
--    - Rows examined should be fewer

-- =====================================================
-- PERFORMANCE MONITORING QUERIES
-- =====================================================
-- Use these queries to monitor index usage and performance

-- Check index usage statistics
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan > 0
ORDER BY idx_scan DESC;

-- Find unused indexes
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND indexname NOT LIKE 'pk_%';

-- Check table and index sizes
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(tablename::regclass)) as total_size,
    pg_size_pretty(pg_relation_size(tablename::regclass)) as table_size,
    pg_size_pretty(pg_total_relation_size(tablename::regclass) - pg_relation_size(tablename::regclass)) as index_size
FROM pg_tables 
WHERE schemaname = 'public';
