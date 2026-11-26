# Standalone devcontainer tools

This directory contains tools that can be run by hand, independent of the devcontainer lifecycle.
Their paths are stable, because they are referenced in messages and in the User's Manual.

| Script | Purpose |
|--------|---------|
| [setup_credentials.sh](setup_credentials.sh) | Enter or validate (`--check`) credentials. Run it manually to re-enter credentials. |
| [check_userns_restriction.sh](check_userns_restriction.sh) | Diagnose (and optionally fix) the host restriction of unprivileged user namespaces that breaks BitBake. |

They are also run automatically as part of the lifecycle hooks, through thin wrapper scripts in
`../lifecycle/<hook>.d/`. Lifecycle steps themselves do not belong here; see
[../lifecycle/README.md](../lifecycle/README.md).
