# Database Index Performance Analysis

## High-Usage Column Identification

Based on analysis of our queries in `joins_queries.sql`, `subqueries.sql`, and `aggregations_and_window_functions.sql`, the following columns are frequently used in WHERE, JOIN, and ORDER BY clauses:

### User Table High-Usage Columns
- **user_id**: Primary key, frequently used in JOINs with Booking and Review tables
- **email**: Used in WHERE clauses for user authentication and lookup
- **role**: Used in WHERE clauses for filtering by user type (guest, host, admin)
- **created_at**: Used in ORDER BY clauses for chronological sorting

### Booking Table High-Usage Columns
- **booking_id**: Primary key
- **user_id**: Foreign key, heavily used in JOINs with User table
- **property_id**: Foreign key, heavily used in JOINs with Property table
- **start_date, end_date**: Used in WHERE clauses for date range queries and availability checks
- **status**: Used in WHERE clauses for filtering bookings by status
- **created_at**: Used in ORDER BY clauses for sorting by booking date
- **total_price**: Used in ORDER BY and aggregation functions

### Property Table High-Usage Columns
- **property_id**: Primary key
- **host_id**: Foreign key, used in JOINs with User table
- **location**: Used in WHERE clauses for location-based searches
- **pricepernight**: Used in WHERE clauses for price filtering and ORDER BY for price sorting
- **name**: Used in ORDER BY clauses and potentially in search queries
- **created_at**: Used in ORDER BY clauses

### Review Table High-Usage Columns
- **review_id**: Primary key
- **property_id**: Foreign key, used in JOINs and GROUP BY for aggregations
- **user_id**: Foreign key, used in JOINs with User table
- **rating**: Used in WHERE clauses, HAVING clauses, and aggregation functions (AVG, COUNT)
- **created_at**: Used in ORDER BY clauses for sorting reviews chronologically

## Existing Indexes Analysis

The current schema already includes the following indexes:
```sql
-- User table
CREATE INDEX idx_user_email ON "User" (email);

-- Property table
CREATE INDEX idx_property_host_id ON Property (host_id);
CREATE INDEX idx_property_property_id ON Property (property_id);

-- Booking table
CREATE INDEX idx_booking_property_id ON Booking (property_id);
CREATE INDEX idx_booking_user_id ON Booking (user_id);
CREATE INDEX idx_booking_booking_id ON Booking (booking_id);

-- Review table
CREATE INDEX idx_review_property_id ON Review (property_id);
CREATE INDEX idx_review_user_id ON Review (user_id);
CREATE INDEX idx_review_review_id ON Review (review_id);
```

## Recommended Additional Indexes

### Single Column Indexes
```sql
-- User table
CREATE INDEX idx_user_role ON "User" (role);
CREATE INDEX idx_user_created_at ON "User" (created_at);

-- Booking table
CREATE INDEX idx_booking_start_date ON Booking (start_date);
CREATE INDEX idx_booking_end_date ON Booking (end_date);
CREATE INDEX idx_booking_status ON Booking (status);
CREATE INDEX idx_booking_created_at ON Booking (created_at);

-- Property table
CREATE INDEX idx_property_location ON Property (location);
CREATE INDEX idx_property_pricepernight ON Property (pricepernight);
CREATE INDEX idx_property_created_at ON Property (created_at);

-- Review table
CREATE INDEX idx_review_rating ON Review (rating);
CREATE INDEX idx_review_created_at ON Review (created_at);
```

### Composite Indexes for Complex Queries
```sql
-- For user role and date filtering
CREATE INDEX idx_user_role_created_at ON "User" (role, created_at);

-- For booking date range queries
CREATE INDEX idx_booking_date_range ON Booking (start_date, end_date);
CREATE INDEX idx_booking_user_status ON Booking (user_id, status);
CREATE INDEX idx_booking_property_status ON Booking (property_id, status);

-- For property location and price searches
CREATE INDEX idx_property_location_price ON Property (location, pricepernight);

-- For review aggregations
CREATE INDEX idx_review_property_rating ON Review (property_id, rating);
```

### Partial Indexes for Specific Use Cases
```sql
-- Index for active bookings only
CREATE INDEX idx_booking_active ON Booking (property_id, start_date) 
WHERE status IN ('confirmed', 'pending');

-- Index for highly rated properties
CREATE INDEX idx_review_high_rating ON Review (property_id) 
WHERE rating >= 4;
```

## Performance Testing Methodology

### Before Adding Indexes
Run these test queries with EXPLAIN ANALYZE:

```sql
-- Query 1: Find bookings by user with date range
EXPLAIN ANALYZE
SELECT * FROM Booking 
WHERE user_id = 'some-uuid' 
AND start_date >= '2024-01-01' 
AND end_date <= '2024-12-31';

-- Query 2: Properties by location and price range
EXPLAIN ANALYZE
SELECT * FROM Property 
WHERE location LIKE '%New York%' 
AND pricepernight BETWEEN 100 AND 300
ORDER BY pricepernight;

-- Query 3: Average rating per property
EXPLAIN ANALYZE
SELECT property_id, AVG(rating) as avg_rating
FROM Review 
GROUP BY property_id 
HAVING AVG(rating) > 4.0;

-- Query 4: User booking count
EXPLAIN ANALYZE
SELECT u.user_id, u.first_name, COUNT(b.booking_id) as booking_count
FROM "User" u 
LEFT JOIN Booking b ON u.user_id = b.user_id 
WHERE u.role = 'guest'
GROUP BY u.user_id, u.first_name
ORDER BY booking_count DESC;

-- Query 5: Properties with recent bookings
EXPLAIN ANALYZE
SELECT DISTINCT p.property_id, p.name, p.location
FROM Property p
INNER JOIN Booking b ON p.property_id = b.property_id
WHERE b.created_at >= CURRENT_DATE - INTERVAL '30 days'
AND b.status = 'confirmed'
ORDER BY p.name;

-- Query 6: Most active hosts
EXPLAIN ANALYZE
SELECT h.user_id, h.first_name, h.last_name, COUNT(b.booking_id) as total_bookings
FROM "User" h
INNER JOIN Property p ON h.user_id = p.host_id
INNER JOIN Booking b ON p.property_id = b.property_id
WHERE h.role = 'host'
GROUP BY h.user_id, h.first_name, h.last_name
ORDER BY total_bookings DESC
LIMIT 10;
```

### After Adding Indexes
Re-run the same queries and compare:
- **Execution time**: Should be significantly reduced
- **Scan type**: Should change from Seq Scan to Index Scan
- **Cost estimates**: Should be lower
- **Rows examined**: Should be fewer due to index filtering

### Expected Performance Improvements

| Query Type | Expected Improvement | Key Benefit |
|------------|---------------------|-------------|
| JOIN operations | 50-90% faster | Foreign key indexes eliminate sequential scans |
| WHERE clause filtering | 70-95% faster | Column-specific indexes enable direct lookups |
| ORDER BY operations | 60-80% faster | Pre-sorted index data eliminates sorting step |
| Date range queries | 80-95% faster | Date indexes enable efficient range scans |
| Aggregation queries | 40-70% faster | Composite indexes optimize GROUP BY operations |
| Text searches | 90-99% faster | GIN indexes enable full-text search capabilities |

### Performance Monitoring Queries

```sql
-- Check index usage statistics
SELECT 
    schemaname, 
    tablename, 
    indexname, 
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan > 0
ORDER BY idx_scan DESC;

-- Find unused indexes
SELECT 
    schemaname, 
    tablename, 
    indexname, 
    idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND indexname NOT LIKE 'pk_%'
ORDER BY tablename, indexname;

-- Check table and index sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - 
                   pg_relation_size(schemaname||'.'||tablename)) as index_size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Analyze query performance
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements
WHERE query LIKE '%Booking%' OR query LIKE '%Property%' OR query LIKE '%User%'
ORDER BY total_time DESC
LIMIT 10;
```

## Index Maintenance Best Practices

### 1. Regular Monitoring
- Monitor index usage with `pg_stat_user_indexes`
- Track query performance with `pg_stat_statements`
- Check for bloated indexes regularly

### 2. Optimization Guidelines
- **Avoid over-indexing**: Each index has maintenance overhead
- **Column order matters**: In composite indexes, put most selective columns first
- **Consider partial indexes**: For large tables with common filter conditions
- **Use covering indexes**: Include frequently accessed columns in index

### 3. Maintenance Schedule
```sql
-- Update table statistics (run weekly)
ANALYZE;

-- Rebuild bloated indexes (run monthly)
REINDEX INDEX idx_name;

-- Check for missing indexes on foreign keys
SELECT 
    tc.table_name, 
    kcu.column_name,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE tablename = tc.table_name 
    AND indexdef LIKE '%' || kcu.column_name || '%'
);
```

### 4. Performance Testing Checklist
- [ ] Baseline performance measurements taken
- [ ] Indexes created in development environment first
- [ ] Query plans analyzed with EXPLAIN ANALYZE
- [ ] Index usage confirmed with pg_stat_user_indexes
- [ ] Performance improvements validated
- [ ] Production deployment scheduled during low-traffic period
- [ ] Post-deployment monitoring established

## Conclusion

Proper indexing strategy can dramatically improve query performance in the AirBnB database. The recommended indexes focus on the most frequently used query patterns and should provide significant performance improvements for:

- User authentication and role-based queries
- Property search and filtering
- Booking date range queries
- Review aggregations and ratings analysis
- Host performance metrics

Regular monitoring and maintenance of these indexes will ensure continued optimal performance as the database grows.
