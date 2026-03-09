---
paths: ["**/*.ts", "**/*.tsx", "**/*.mts", "**/tsconfig*.json", "**/package.json"]
---
# TypeScript

## Toolchain

| purpose | tool |
|---------|------|
| package manager | `pnpm` (NEVER npm, yarn, or bun) |
| lint | `oxlint` (prefer over eslint) |
| format | `oxfmt` (prefer over prettier) |
| test | `vitest` |
| types | `tsc --noEmit` |

## Rules

- Use ESM only (`"type": "module"` in package.json).
- Install: `pnpm add <package>`. Run: `pnpm run <script>`. Execute: `pnpm dlx <package>`.
- Never use `any` -- use `unknown` instead.
- Enable all strict options in tsconfig.json:
  ```jsonc
  "strict": true,
  "noUncheckedIndexedAccess": true,
  "exactOptionalPropertyTypes": true,
  "noImplicitOverride": true,
  "noPropertyAccessFromIndexSignature": true,
  "verbatimModuleSyntax": true,
  "isolatedModules": true
  ```
- Use `satisfies` operator for type constraints and `as const` for literal types.
- Prefer interfaces over type aliases. One export per file. No index file re-exports.
- Colocate test files as `*.test.ts` alongside source code.
- Pin exact versions (no `^` or `~`). Run `pnpm audit --audit-level=moderate`.
- Set `minimumReleaseAge: 1440` in pnpm-workspace.yaml to avoid installing packages less than 24h old.
- `oxlint` plugins: `typescript`, `import`, `unicorn`.
- Supply chain: `pnpm config set ignore-scripts true`.

## Naming Conventions

- Classes/Interfaces: `PascalCase`
- Variables/Functions: `camelCase`
- Files/Directories: `kebab-case`
- Constants/Env vars: `UPPERCASE`
- Booleans: `is*`, `has*`, `can*`
