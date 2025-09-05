# Advanced Database Scripts

This directory contains advanced SQL scripts for the AirBnB database project, focusing on complex queries, joins, and performance optimization.

## Files Overview

### joins_queries.sql
Contains various SQL JOIN operations demonstrating different types of joins and their use cases.

### subqueries.sql
Contains advanced SQL subqueries including correlated subqueries, nested queries, and complex filtering operations.

### aggregations_and_window_functions.sql
Contains SQL aggregation functions with GROUP BY clauses and window functions for ranking and analytical operations.

## JOIN Queries Explained

### 1. INNER JOIN - Bookings with Users
```sql
SELECT b.*, u.* FROM Booking b INNER JOIN "User" u ON b.user_id = u.user_id
```
**Purpose**: Retrieves all bookings along with the user information for each booking.
**Result**: Only returns records where both booking and user exist (should be all bookings due to foreign key constraints).
**Use Case**: When you need complete booking information including guest details.

### 2. LEFT JOIN - Properties with Reviews
```sql
SELECT p.*, r.* FROM Property p LEFT JOIN Review r ON p.property_id = r.property_id
```
**Purpose**: Retrieves all properties and their associated reviews, including properties that have no reviews.
**Result**: All properties appear in the result set, with NULL values for review columns where no reviews exist.
**Use Case**: When you want to see all properties in your inventory, regardless of whether they have been reviewed.

### 3. FULL OUTER JOIN - Users and Bookings
```sql
SELECT u.*, b.* FROM "User" u FULL OUTER JOIN Booking b ON u.user_id = b.user_id
```
**Purpose**: Retrieves all users and all bookings, showing unmatched records from both sides.
**Result**: Shows users who haven't made any bookings and any orphaned bookings (though this shouldn't happen with proper foreign key constraints).
**Use Case**: Data integrity checks and comprehensive user/booking analysis.

## Key Learning Points

1. **INNER JOIN**: Only returns matching records from both tables
2. **LEFT JOIN**: Returns all records from the left table and matched records from the right table
3. **RIGHT JOIN**: Returns all records from the right table and matched records from the left table
4. **FULL OUTER JOIN**: Returns all records from both tables, with NULLs for non-matching records

____________________________________

## Subqueries Explained

### 1. Properties with Average Rating > 4.0
```sql
SELECT p.* FROM Property p WHERE p.property_id IN (
    SELECT r.property_id FROM Review r 
    GROUP BY r.property_id HAVING AVG(r.rating) > 4.0
)
```
**Purpose**: Finds properties that have received high ratings on average.
**Type**: Subquery with IN operator and HAVING clause.
**Use Case**: Identifying top-rated properties for promotional purposes.

### 2. Users with More Than 3 Bookings (Correlated Subquery)
```sql
SELECT u.* FROM "User" u WHERE (
    SELECT COUNT(*) FROM Booking b WHERE b.user_id = u.user_id
) > 3
```
**Purpose**: Identifies frequent customers who have made multiple bookings.
**Type**: Correlated subquery that references the outer query.
**Use Case**: Customer loyalty programs and targeted marketing.

## Subquery Types and Performance

1. **Simple Subqueries**: Independent queries that can be executed separately
2. **Correlated Subqueries**: Reference columns from the outer query, executed once per outer row
3. **EXISTS Subqueries**: Check for existence of matching records, often more efficient than IN
4. **Scalar Subqueries**: Return single values, useful in SELECT and WHERE clauses

## Performance Considerations

- Correlated subqueries can be expensive as they execute for each outer row
- Consider using JOINs instead of subqueries when possible for better performance
- EXISTS is often faster than IN for large datasets
- Use appropriate indexes on columns used in subquery conditions

## Aggregations and Window Functions Explained

### 1. Total Bookings per User (COUNT with GROUP BY)
```sql
SELECT u.user_id, u.first_name, u.last_name, COUNT(b.booking_id) AS total_bookings
FROM "User" u LEFT JOIN Booking b ON u.user_id = b.user_id
GROUP BY u.user_id, u.first_name, u.last_name
```
**Purpose**: Counts total bookings made by each user, including users with zero bookings.
**Type**: Aggregation function with GROUP BY clause.
**Use Case**: Customer activity analysis and user engagement metrics.

### 2. Property Rankings by Booking Count (Window Functions)
```sql
SELECT p.*, COUNT(b.booking_id) AS total_bookings,
       ROW_NUMBER() OVER (ORDER BY COUNT(b.booking_id) DESC) AS row_number_rank,
       RANK() OVER (ORDER BY COUNT(b.booking_id) DESC) AS rank_position
FROM Property p LEFT JOIN Booking b ON p.property_id = b.property_id
GROUP BY p.property_id
```
**Purpose**: Ranks properties based on popularity (total bookings).
**Type**: Window functions for ranking analysis.
**Use Case**: Identifying top-performing properties and market analysis.

## Window Functions vs Aggregations

1. **Aggregation Functions**: Reduce multiple rows to single summary values (COUNT, SUM, AVG)
2. **Window Functions**: Perform calculations across related rows without collapsing them
3. **ROW_NUMBER()**: Assigns unique sequential numbers, no ties
4. **RANK()**: Assigns same rank to ties, skips subsequent ranks
5. **DENSE_RANK()**: Assigns same rank to ties, doesn't skip subsequent ranks


