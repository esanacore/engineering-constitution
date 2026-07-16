---
name: "dependency-rule-enforcer"
description: "Ensures inner business logic layers do not depend on outer infrastructure layers."
---
# Dependency Rule Enforcer

Use this skill to validate imports. Domain/business logic MUST NOT import ORMs, HTTP frameworks, or concrete UI components. Use Dependency Inversion.

**Constitution Alignment**: This skill strictly enforces the principles laid out in Eric's Engineering Constitution. Always adhere to the established workflows when applying this skill.
