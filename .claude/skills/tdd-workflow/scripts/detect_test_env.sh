#!/bin/bash
# Detect test framework, runner, and conventions from project structure.
# Run from the project root directory.
# Output: key=value pairs describing the test environment.

set -euo pipefail

echo "=== Test Environment Detection ==="

# --- Language / Runtime Detection ---

if [ -f "package.json" ]; then
  echo "runtime=node"

  # Detect test framework from dependencies
  if grep -q '"vitest"' package.json 2>/dev/null; then
    echo "framework=vitest"
  elif grep -q '"jest"' package.json 2>/dev/null; then
    echo "framework=jest"
  elif grep -q '"mocha"' package.json 2>/dev/null; then
    echo "framework=mocha"
  elif grep -q '"ava"' package.json 2>/dev/null; then
    echo "framework=ava"
  fi

  # Detect test script
  test_cmd=$(node -e "try{const p=require('./package.json');console.log(p.scripts?.test||'')}catch(e){}" 2>/dev/null || true)
  if [ -n "$test_cmd" ]; then
    echo "test_script=npm test"
    echo "test_script_raw=$test_cmd"
  fi

  # Detect package manager
  if [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
    echo "pkg_manager=bun"
  elif [ -f "pnpm-lock.yaml" ]; then
    echo "pkg_manager=pnpm"
  elif [ -f "yarn.lock" ]; then
    echo "pkg_manager=yarn"
  else
    echo "pkg_manager=npm"
  fi

elif [ -f "pyproject.toml" ] || [ -f "setup.cfg" ] || [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
  echo "runtime=python"
  echo "framework=pytest"
  echo "test_script=pytest"

elif [ -f "go.mod" ]; then
  echo "runtime=go"
  echo "framework=go-test"
  echo "test_script=go test ./..."

elif [ -f "Cargo.toml" ]; then
  echo "runtime=rust"
  echo "framework=cargo-test"
  echo "test_script=cargo test"

elif [ -f "pom.xml" ]; then
  echo "runtime=java"
  echo "framework=maven"
  echo "test_script=mvn test"

elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  echo "runtime=java"
  echo "framework=gradle"
  echo "test_script=./gradlew test"

elif [ -f "mix.exs" ]; then
  echo "runtime=elixir"
  echo "framework=exunit"
  echo "test_script=mix test"

elif [ -f "Gemfile" ]; then
  echo "runtime=ruby"
  if grep -q 'rspec' Gemfile 2>/dev/null; then
    echo "framework=rspec"
    echo "test_script=bundle exec rspec"
  else
    echo "framework=minitest"
    echo "test_script=bundle exec rake test"
  fi

else
  echo "runtime=unknown"
  echo "framework=unknown"
fi

# --- Test File Pattern Detection ---

echo ""
echo "=== Existing Test Files (sample) ==="

# Find test files and show first 10
test_files=$(find . -maxdepth 5 \
  \( -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" -o -name "test_*.*" \) \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/vendor/*" \
  -not -path "*/dist/*" \
  2>/dev/null | head -10)

if [ -n "$test_files" ]; then
  echo "$test_files"

  # Detect naming pattern from existing files
  if echo "$test_files" | grep -q '\.test\.' 2>/dev/null; then
    echo "file_pattern=*.test.*"
  elif echo "$test_files" | grep -q '\.spec\.' 2>/dev/null; then
    echo "file_pattern=*.spec.*"
  elif echo "$test_files" | grep -q '_test\.' 2>/dev/null; then
    echo "file_pattern=*_test.*"
  elif echo "$test_files" | grep -q 'test_' 2>/dev/null; then
    echo "file_pattern=test_*.*"
  fi
else
  echo "(no existing test files found)"
fi

# --- Test Directory Detection ---

echo ""
echo "=== Test Directories ==="

for dir in __tests__ tests test spec e2e cypress; do
  if [ -d "$dir" ]; then
    echo "test_dir=$dir"
  fi
done

# --- Config File Detection ---

echo ""
echo "=== Test Config Files ==="

for cfg in jest.config.js jest.config.ts jest.config.mjs \
           vitest.config.js vitest.config.ts vitest.config.mjs \
           .mocharc.yml .mocharc.json mocha.opts \
           pytest.ini pyproject.toml setup.cfg \
           playwright.config.ts playwright.config.js \
           cypress.config.ts cypress.config.js; do
  if [ -f "$cfg" ]; then
    echo "config_file=$cfg"
  fi
done

echo ""
echo "=== Detection Complete ==="
