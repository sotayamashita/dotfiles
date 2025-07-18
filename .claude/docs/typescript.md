# TypeScript

## Package Management

- **CRITICAL**: Use `pnpm` exclusively - NEVER `npm`, `yarn`, or `bun`
- Install packages: `pnpm add <package>`
- Run scripts: `pnpm run <script>`
- Execute packages: `pnpm dlx <package> <command args...>`

## Type Safety

- **CRITICAL**: Enable strict mode in `tsconfig.json`
- **FORBIDDEN**: Using `any` - use `unknown` instead
- Prefer `unknown` over `any` for type-safe handling
- Use explicit type annotations for clarity
- Leverage type guards and narrowing

## Modern TypeScript Features

- Use `satisfies` operator for type constraints
- Apply `as const` assertions for literal types
- Leverage template literal types for string patterns
- Use utility types: `Partial`, `Readonly`, `Pick`, `Omit`
- Create custom utility types for specific needs

## Code Organization

- **IMPORTANT**: One export per file
- **FORBIDDEN**: Index file re-exports
- Prefer interfaces over type aliases
- Use composition over inheritance
- Create small, focused interfaces

## Naming Conventions

- Classes/Interfaces: `PascalCase`
- Variables/Functions: `camelCase`
- Files/Directories: `kebab-case`
- Constants/Env vars: `UPPERCASE`
- Booleans: `is*`, `has*`, `can*`
- Functions start with verbs

## Best Practices

- Document with JSDoc for public APIs
- Write self-documenting code
- Use const assertions and readonly modifiers
- Apply runtime validation with `zod` when needed
- Avoid enums - use const objects or union types

## Type Declaration Guidelines

- Search existing types with DeepWiki MCP before creating new ones
- Create precise, descriptive types
- Use branded types for sensitive data
- Favor immutable data structures
