-- Advanced SQL Aggregations and Window Functions
-- File: aggregations_and_window_functions.sql

-- =====================================================
-- AGGREGATION: Find the total number of bookings made by each user using COUNT and GROUP BY
-- =====================================================
-- This query groups users and counts their bookings

SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    u.role,
    COUNT(b.booking_id) AS total_bookings
FROM "User" u
LEFT JOIN Booking b ON u.user_id = b.user_id
GROUP BY u.user_id, u.first_name, u.last_name, u.email, u.role
ORDER BY total_bookings DESC, u.last_name, u.first_name;

-- =====================================================
-- WINDOW FUNCTION: Rank properties based on total number of bookings using ROW_NUMBER and RANK
-- =====================================================
-- This query uses window functions to rank properties by booking count

SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight,
    h.first_name || ' ' || h.last_name AS host_name,
    COUNT(b.booking_id) AS total_bookings,
    ROW_NUMBER() OVER (ORDER BY COUNT(b.booking_id) DESC) AS row_number_rank,
    RANK() OVER (ORDER BY COUNT(b.booking_id) DESC) AS rank_position,
    DENSE_RANK() OVER (ORDER BY COUNT(b.booking_id) DESC) AS dense_rank_position
FROM Property p
INNER JOIN "User" h ON p.host_id = h.user_id
LEFT JOIN Booking b ON p.property_id = b.property_id
GROUP BY p.property_id, p.name, p.location, p.pricepernight, h.first_name, h.last_name
ORDER BY total_bookings DESC, p.name;
