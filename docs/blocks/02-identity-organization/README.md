# GSI ONE — Block 02 Package

This package turns Master PRD Epics 003–004 into an implementation-ready Codex task.

Files:

- `BLOCK_02_SPEC.md` — authoritative functional/technical specification for this block.
- `001_identity_org_localization.sql` — schema hardening delta after the v1 baseline.
- `seed_identity_org_localization.sql` — languages, currencies, countries, permissions and role templates.
- `openapi.identity-org-localization.yaml` — API contract fragment to merge into the main contract.
- `CODEX_BLOCK_02_PROMPT.md` — prompt to paste into Codex after repository bootstrap/database foundation.
- `TEST_MATRIX.md` — mandatory access-control/localization/sequence tests.

Recommended Codex instruction:

> Read `CODEX_SYSTEM_PROMPT.md`, the Master PRD and every file in this Block 02 package. Implement Block 02 only. Do not proceed to CRM or Jobs until all authorization-isolation tests pass.
