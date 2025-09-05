-- Advanced SQL Joins Queries
-- File: joins_queries.sql

-- =====================================================
-- INNER JOIN: Retrieve all bookings and the respective users who made those bookings
-- =====================================================
-- This query returns only bookings that have a matching user (which should be all bookings due to foreign key constraint)

SELECT 
    b.booking_id,
    b.property_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    b.created_at AS booking_created_at,
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    u.phone_number,
    u.role
FROM Booking b
INNER JOIN "User" u ON b.user_id = u.user_id
ORDER BY b.created_at DESC;

-- =====================================================
-- LEFT JOIN: Retrieve all properties and their reviews, including properties that have no reviews
-- =====================================================
-- This query returns all properties, even those without any reviews

SELECT 
    p.property_id,
    p.name AS property_name,
    p.description,
    p.location,
    p.pricepernight,
    p.created_at AS property_created_at,
    r.review_id,
    r.rating,
    r.comment,
    r.created_at AS review_created_at,
    u.first_name AS reviewer_first_name,
    u.last_name AS reviewer_last_name
FROM Property p
LEFT JOIN Review r ON p.property_id = r.property_id
LEFT JOIN "User" u ON r.user_id = u.user_id
ORDER BY p.name, r.created_at DESC;

-- =====================================================
-- FULL OUTER JOIN: Retrieve all users and all bookings, even if the user has no booking or a booking is not linked to a user
-- =====================================================
-- This query returns all users and all bookings, showing unmatched records from both sides

SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    u.role,
    u.created_at AS user_created_at,
    b.booking_id,
    b.property_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    b.created_at AS booking_created_at
FROM "User" u
FULL OUTER JOIN Booking b ON u.user_id = b.user_id
ORDER BY u.last_name, u.first_name, b.created_at DESC;

-- =====================================================
-- Additional query variations and explanations
-- =====================================================

-- Alternative INNER JOIN with more detailed booking information including property details
SELECT 
    b.booking_id,
    u.first_name || ' ' || u.last_name AS guest_name,
    u.email AS guest_email,
    p.name AS property_name,
    p.location AS property_location,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status
FROM Booking b
INNER JOIN "User" u ON b.user_id = u.user_id
INNER JOIN Property p ON b.property_id = p.property_id
ORDER BY b.start_date DESC;

-- LEFT JOIN with aggregated review statistics per property
SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight,
    COUNT(r.review_id) AS total_reviews,
    AVG(r.rating) AS average_rating,
    MAX(r.created_at) AS latest_review_date
FROM Property p
LEFT JOIN Review r ON p.property_id = r.property_id
GROUP BY p.property_id, p.name, p.location, p.pricepernight
ORDER BY average_rating DESC NULLS LAST, total_reviews DESC;

-- FULL OUTER JOIN showing users without bookings and orphaned bookings (if any)
SELECT 
    CASE 
        WHEN u.user_id IS NULL THEN 'ORPHANED BOOKING'
        ELSE u.first_name || ' ' || u.last_name 
    END AS user_name,
    u.email,
    u.role,
    CASE 
        WHEN b.booking_id IS NULL THEN 'NO BOOKINGS'
        ELSE b.booking_id::TEXT 
    END AS booking_info,
    b.status,
    b.total_price
FROM "User" u
FULL OUTER JOIN Booking b ON u.user_id = b.user_id
WHERE u.user_id IS NULL OR b.booking_id IS NULL
ORDER BY u.last_name NULLS LAST;
