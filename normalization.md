# Database Normalization for AirBnB Schema

## 1. Review of the Provided Schema

The provided schema consists of the following entities:
- **User**
- **Property**
- **Booking**
- **Payment**
- **Review**
- **Message**

Each entity has a clear primary key, and foreign key relationships are defined appropriately. The schema also specifies constraints and indexes.

## 2. Normalization Analysis

### First Normal Form (1NF)
- All tables have atomic values (no repeating groups or arrays).
- Each field contains only one value per record.

### Second Normal Form (2NF)
- All non-key attributes are fully functionally dependent on the primary key in each table.
- No partial dependencies exist, as all primary keys are single-column (UUIDs).

### Third Normal Form (3NF)
- All attributes are functionally dependent only on the primary key.
- No transitive dependencies are present (i.e., non-key attributes do not depend on other non-key attributes).

## 3. Potential Redundancies or Violations

- **User Table**: No redundancies. All attributes depend on `user_id`.
- **Property Table**: All attributes depend on `property_id`. `host_id` is a foreign key, not a transitive dependency.
- **Booking Table**: All attributes depend on `booking_id`. No transitive dependencies.
- **Payment Table**: All attributes depend on `payment_id`. `booking_id` is a foreign key.
- **Review Table**: All attributes depend on `review_id`. No transitive dependencies.
- **Message Table**: All attributes depend on `message_id`. No transitive dependencies.

## 4. Adjustments for 3NF

The schema as provided is already in 3NF:
- No repeating groups (1NF)
- No partial dependencies (2NF)
- No transitive dependencies (3NF)

### Additional Notes
- Indexes on foreign keys and unique fields (like `email`) are appropriate for performance.
- ENUM types are used for roles and statuses, which is acceptable for small, fixed sets of values.
- All foreign key relationships are direct and do not introduce redundancy.

## 5. Conclusion

**No changes are required** to achieve 3NF. The schema is well-structured, normalized, and avoids redundancy.

---

**Summary Table:**

| Table    | 1NF | 2NF | 3NF | Notes                |
|----------|-----|-----|-----|----------------------|
| User     | ✔   | ✔   | ✔   | No issues            |
| Property | ✔   | ✔   | ✔   | No issues            |
| Booking  | ✔   | ✔   | ✔   | No issues            |
| Payment  | ✔   | ✔   | ✔   | No issues            |
| Review   | ✔   | ✔   | ✔   | No issues            |
| Message  | ✔   | ✔   | ✔   | No issues            |

If you have further requirements or wish to denormalize for performance, consider those as separate design steps.
