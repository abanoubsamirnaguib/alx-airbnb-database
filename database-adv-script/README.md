# Advanced Database Scripts

This directory contains advanced SQL scripts for the AirBnB database project, focusing on complex queries, joins, and performance optimization.

## Files Overview

### joins_queries.sql
Contains various SQL JOIN operations demonstrating different types of joins and their use cases.

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

## Query Performance Tips

- Always use appropriate indexes on JOIN columns
- Consider the order of JOINs for optimal performance
- Use WHERE clauses to filter results early
- Consider using EXISTS instead of IN for subqueries

## Sample Data Requirements

To test these queries effectively, ensure your database has:
- Users with and without bookings
- Properties with and without reviews
- Various booking statuses
- Multiple reviews per property (some properties)

## Running the Queries

Execute the queries in order, or run individual queries as needed. Make sure the database schema is properly set up before running these queries.
