---
name: "secrets-sweep-enforcer"
description: "Runs check_secrets.sh, analyzes files for credentials, and adds findings to .gitignore."
---
# Secrets Sweep Enforcer

Use this skill before completing work. Run `bash constitution/scripts/check_secrets.sh .` locally. If any credential-shaped files are found, add them to `.gitignore` and ensure they are removed from tracking.

**Constitution Alignment**: This skill strictly enforces the principles laid out in Eric's Engineering Constitution. Always adhere to the established workflows when applying this skill.
