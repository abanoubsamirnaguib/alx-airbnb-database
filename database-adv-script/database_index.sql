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
