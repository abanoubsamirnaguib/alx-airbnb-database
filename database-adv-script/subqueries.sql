-- Advanced SQL Subqueries
-- File: subqueries.sql

-- =====================================================
-- SUBQUERY: Find all properties where the average rating is greater than 4.0
-- =====================================================
-- This query uses a subquery to calculate average ratings and filter properties

SELECT 
    p.property_id,
    p.name AS property_name,
    p.description,
    p.location,
    p.pricepernight,
    p.created_at,
    h.first_name || ' ' || h.last_name AS host_name,
    h.email AS host_email
FROM Property p
INNER JOIN "User" h ON p.host_id = h.user_id
WHERE p.property_id IN (
    SELECT r.property_id
    FROM Review r
    GROUP BY r.property_id
    HAVING AVG(r.rating) > 4.0
)
ORDER BY p.name;

-- =====================================================
-- CORRELATED SUBQUERY: Find users who have made more than 3 bookings
-- =====================================================
-- This query uses a correlated subquery to count bookings per user

SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    u.phone_number,
    u.role,
    u.created_at AS user_created_at,
    (SELECT COUNT(*) 
     FROM Booking b 
     WHERE b.user_id = u.user_id) AS total_bookings
FROM "User" u
WHERE (
    SELECT COUNT(*)
    FROM Booking b
    WHERE b.user_id = u.user_id
) > 3
ORDER BY total_bookings DESC, u.last_name, u.first_name;
