# Security Policy

## Supported Scope

This project is a shell-script driven DWM setup/installer.
Security support covers:

- scripts in `scripts/`
- CI checks in `.github/workflows/`
- config deployment logic in `rofi/`, `dwmblocks/`, `profiles/`, `sessions/`, and top-level startup/config files

It does **not** guarantee security for:

- third-party packages installed by distro package managers
- user-modified local configs after deployment
- host OS misconfiguration outside this repo

## Threat Model

Main risks in this repo:

1. Command injection through script arguments or environment variables.
2. Unsafe overwrite/delete operations in deployment/uninstall flows.
3. Excessive root/sudo operations.
4. Supply-chain risk from package managers and external tools.

## Current Security Controls

- Input validation for key script flags (`--profile`, `--display-manager`, etc.).
- `--backup` support in install/deploy/theme scripts before overwrite.
- `--dry-run` support in major scripts for previewing changes.
- CI linting and syntax checks (`bash -n` + `shellcheck`).
- Health and rollback scripts:
  - `scripts/health-check.sh`
  - `scripts/uninstall-dwm-stack.sh`

## Safe Usage Guidance

1. Always run `--dry-run` first on new systems.
2. Prefer `--backup` when replacing existing configs.
3. Review script changes before running with sudo/root.
4. Use trusted package mirrors and keep OS CA certificates updated.
5. Avoid running scripts from untrusted forks without review.

## Reporting a Vulnerability

If you find a security issue:

1. Do **not** open a public issue with exploit details.
2. Email: `melauin16@gmail.com`
3. Include:
   - affected script/path
   - reproduction steps
   - impact assessment
   - suggested fix (if available)

I will acknowledge reports as soon as possible and coordinate a fix and disclosure.

## Disclosure

- Please allow reasonable time for patching before public disclosure.
- After fix release, details can be disclosed responsibly.

