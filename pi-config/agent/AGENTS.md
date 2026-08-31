# Global development instructions

For all code changes, default to TDD using the red-green-refactor loop:

1. Red: add or update a failing test that captures the desired behavior or bug.
2. Green: implement the smallest change that makes the focused test pass.
3. Refactor: clean up only after tests are green.
4. Validate with the focused test first, then relevant broader tests.

If TDD is impractical for a change, explicitly state why before implementing.
