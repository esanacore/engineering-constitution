# Environment & Configuration Contract

This framework declares no environment variables of its own: the scripts read
only their arguments and the working tree, and there is no `.env.example` or
`docker-compose.yml` manifest for `scripts/check_env_vars.sh` to cross-check.

The one environment variable the scripts *react to* is set by the host, not by
this project:

| Variable | Description | Required | Default |
| :--- | :--- | :--- | :--- |
| `GITHUB_ACTIONS` | Set to `true` by GitHub Actions. When present, every checker also prints `::warning::` / `::error::` workflow commands so findings surface in the pull request UI (see `scripts/lib/ci_annotations.sh`). Never set it by hand outside a workflow. | No | unset |

If a manifest is ever added to this repository, document its variables here in
the same change and the checker will begin enforcing the contract.
