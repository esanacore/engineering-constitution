---
name: "test-pyramid-balancer"
description: "Analyzes the test suite to ensure a healthy ratio of unit, integration, and E2E tests."
---
# Test Pyramid Balancer

Use this skill to prevent over-reliance on heavy E2E tests. Push tests down the pyramid where possible. If a module has no unit tests but is covered by an E2E test, scaffold the missing unit tests.

**Constitution Alignment**: This skill strictly enforces the principles laid out in Eric's Engineering Constitution. Always adhere to the established workflows when applying this skill.
