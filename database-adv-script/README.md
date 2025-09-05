# Advanced Database Scripts

This directory contains advanced SQL scripts for the AirBnB database project, focusing on complex queries, joins, and performance optimization.

## Files Overview

### joins_queries.sql
Contains various SQL JOIN operations demonstrating different types of joins and their use cases.

### subqueries.sql
Contains advanced SQL subqueries including correlated subqueries, nested queries, and complex filtering operations.

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

____________________________________


