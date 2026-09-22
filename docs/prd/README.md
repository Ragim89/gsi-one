# GSI ONE — Block 03 Package

This package implements the next logical layer after Block 02:

**Counterparties + CRM + Contacts + Contracts + Pricing + Client Preferences**

## Files

- `BLOCK_03_SPEC.md` — implementation specification
- `002_commercial_crm.sql` — PostgreSQL hardening/migration after baseline + Block 02
- `seed_commercial.sql` — idempotent counterparty type + permission seed
- `openapi.commercial.yaml` — Block 03 API fragment
- `TEST_MATRIX.md` — mandatory functional/security/pricing tests
- `CODEX_BLOCK_03_PROMPT.md` — ready-to-run Codex implementation prompt

## Dependency order

1. Repository bootstrap
2. Master baseline schema
3. Block 02 Identity + Organization + Localization
4. **Block 03 Commercial**
5. Block 04 Job / Inspection Order Core

## Why this block comes before Jobs

A Job must reference stable commercial objects rather than free-text:

- client/counterparty
- owner legal entity/branch
- contract + exact contract version
- service(s)
- accepted quote/revision when available
- resolved/snapshotted commercial terms
- document/billing preferences

That is what Block 03 establishes.
