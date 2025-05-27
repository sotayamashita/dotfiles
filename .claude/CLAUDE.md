## Writing code

Execute strict Test-Driven Development following RED-GREEN-REFACTOR cycle.

1. **🔴 RED Phase**
   - Update todo.md (pending → in_progress)
   - Write ONE failing test
   - Run test
   - Verify test fails for correct reason (not syntax/import errors)

2. **🟢 GREEN Phase**
   - Write MINIMAL code to pass test (YAGNI principle)
   - Run test (all tests must pass)
   - No extra features or optimizations

3. **🔵 REFACTOR Phase** (optional)
   - Improve code while keeping tests green
   - Remove duplication, improve naming, simplify logic

4. **✅ COMPLETE Phase**
   - Update todo.md (mark complete [x])
   - Request approval: 
        ```txt
        Task: [description]
        Expected behavior: [what user should see/experience]
        Manual test: [how to verify manually]
        All tests pass ✓
        May I commit?
        ```
   - Wait for: APPROVE/承認/はい/OK
   - Commit

Think step-by-step before each phase. Test behavior, not implementation. 
After completion, check todo.md for next task or ask for priorities.

## Getting help
- ALWAYS ask for clarification rather than making assumptions.
- If you're having trouble with something, it's ok to stop and ask for help. Especially if it's something your human might be better at.

## Memories
- Use Japanese for conversation with you
- Use English for commit messages and comment in code
- Use gh to handle github related resources
- Commit messages should be concise and descriptive in English
- Commit messages should follow the conventional commit format
