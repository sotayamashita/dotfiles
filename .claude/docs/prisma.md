# Prisma

## Schema Design

- Use domain-driven model names
- **CRITICAL**: Use @id for primary keys
- Use @unique for natural unique identifiers
- Use @relation for explicit relationships
- Keep schemas normalized and DRY
- Implement soft delete with deletedAt timestamp
- Use Prisma's native type decorators

## Client Usage

- **CRITICAL**: Use type-safe operations only
- Use transactions for multi-step operations
- Implement middleware for:
  - Logging
  - Soft delete
  - Auditing
- Handle optional relations explicitly
- Use built-in filtering and pagination

## Migrations

- **IMPORTANT**: Never modify existing migrations
- Use descriptive migration names
- Review before applying
- Keep migrations idempotent

## Error Handling

- Handle Prisma-specific errors:
  - PrismaClientKnownRequestError
  - PrismaClientUnknownRequestError
  - PrismaClientValidationError
- Provide user-friendly messages
- Log detailed error context

## Testing

- Use in-memory database for unit tests
- Mock Prisma client for isolation
- Test all scenarios: success, errors, edge cases
- Use factory methods for test data
- Run integration tests with real database

## Performance

- **CRITICAL**: Avoid N+1 query problems
- Use select/include judiciously
- Use findMany with take/skip for pagination
- Use distinct for unique results
- Profile and optimize queries

## Security

- **CRITICAL**: Never expose raw Prisma client in APIs
- **IMPORTANT**: Validate input before database operations
- Implement row-level security
- Sanitize all user inputs
- Leverage built-in SQL injection protection

## Code Organization

- Keep Prisma code in dedicated modules
- Separate data access from business logic
- Use repository patterns for complex queries
- Use dependency injection for services
