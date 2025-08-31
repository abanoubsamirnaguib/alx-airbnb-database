# AirBnB Database Schema

This directory contains the SQL script to create the AirBnB database schema, including all tables, constraints, and indexes as per the specification.

## Files
- `schema.sql`: SQL script to create all tables, constraints, and indexes.

## How to Use
1. Ensure your database supports the `uuid-ossp` extension (for UUID generation).
2. Run the `schema.sql` script in your SQL client or database management tool.

## Tables Defined
- User
- Property
- Booking
- Payment
- Review
- Message

Each table includes:
- Proper data types
- Primary keys (UUID)
- Foreign keys
- Constraints (unique, not null, check)
- Indexes for performance

---

For normalization details, see the `normalization.md` file in the project root.
