# Operations

This framework has no deployed service. Its operational surface is the
release process and the automation that keeps adopters current. For the
standards this document follows, see the root `OPERATIONS.md`.

## Deployment

- **Environments**: `main` is the only long-lived branch and is what adopters
  pin. Feature branches are deleted after merge.
- **Deployment procedure**: cutting a release, per `RELEASES.md`'s "Cutting a
  Release" gate — bump `VERSION` and every version reference, date the
  `CHANGELOG.md` section, run the full suite, merge, tag `vX.Y.Z`, publish the
  GitHub Release, then bump the adopter fleet with `scripts/bump_adopters.sh`.
- **Approvals / gates**: every change goes through a pull request; CI runs
  `.github/workflows/tests.yml` (all suites plus the self-governance
  checkers). Tags are pushed only after the release commit is on `main`.
- **Rollback**: a bad release is superseded, never deleted — publish a patch
  release with the fix. Adopters pin by submodule SHA, so a broken tag never
  reaches them until they bump; if a tag was pushed onto the wrong commit,
  move it only before any adopter has pinned it and re-run
  `scripts/check_release_tag_alignment.sh`.

## Monitoring & Observability

- **Logs**: GitHub Actions run logs for `tests.yml`, `wiki-sync.yml`, and
  `release-tag-alignment.yml`.
- **Metrics**: `scripts/audit_adopters.sh` reports which adopters are behind
  the latest release; `scripts/measure_instruction_weight.sh` reports the
  session-start reading cost.
- **Alerts**: a failing workflow run on `main` notifies the maintainer through
  GitHub's default watch notifications; there is no paging.

## Safe Operations

- **Backup / restore**: the repository and its wiki are plain Git; GitHub is
  the primary remote and any clone is a full backup.
- **Maintenance mode**: not applicable.
- **Stateful changes**: the only state is the release tag history and the
  adopter fleet's submodule pins. Never rewrite a pushed tag that an adopter
  may already pin (see `docs/MEMORY.md` for the v1.44.0 lesson).

## Incident Response

1. Identify the impact: a red `main`, a broken tag, or a fleet-wide adopter
   gate failure.
2. Check the failing workflow run and the most recent merge.
3. Fix forward on a branch and cut a patch release; for a fleet-wide gate
   failure caused by a release, roll the bump with `scripts/bump_adopters.sh`
   rather than asking each adopter to catch up by hand.
4. Record the cause and the corrective action in `CHANGELOG.md` and, when it
   changes a rule, in `docs/MEMORY.md` (on approval). Use
   `templates/docs/INCIDENT_POSTMORTEM.md` for anything that took more than
   one session to resolve.
