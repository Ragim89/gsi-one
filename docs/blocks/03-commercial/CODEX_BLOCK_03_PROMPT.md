# Codex Task Prompt — GSI ONE Block 03

You are implementing **Block 03: Counterparties + CRM + Contacts + Contracts + Pricing + Client Preferences** for GSI ONE.

Read before coding:

1. `CODEX_SYSTEM_PROMPT.md`
2. `GSI_ERP_MASTER_PRD_v1.0.md`
3. `BLOCK_02_SPEC.md`
4. `BLOCK_03_SPEC.md`
5. `schema.sql`
6. `001_identity_org_localization.sql`
7. `002_commercial_crm.sql`
8. `seed_identity_org_localization.sql`
9. `seed_commercial.sql`
10. main `openapi.yaml`
11. `openapi.identity-org-localization.yaml`
12. `openapi.commercial.yaml`
13. `TEST_MATRIX.md`

## Goal

Implement the commercial master-data layer required for future Job creation:

`Counterparty → Contacts/Preferences → Contract Version → Service → Price Resolution → Quote/Revision → Accepted Commercial Snapshot`

Do **not** implement Jobs or later operational modules.

## Mandatory implementation order

### 1. Integrate DB migration + seed

- Add Block 03 migration to the repository migration framework.
- Do not rewrite already-applied Block 01/02 migrations.
- Seed counterparty type catalog and permissions idempotently.
- Bind permissions to existing role codes via application seed logic.
- Preserve legacy baseline columns for compatibility where the migration says so.

### 2. Add permission policies

Implement all Block 03 permission codes.

All APIs must use the Block 02 authorization engine:
`active user + permission + organizational scope + record visibility + contextual policy`.

Do not rely on frontend hiding.

### 3. Counterparty visibility first

Before normal CRUD, implement `CounterpartyVisibilityService`.

Required negative tests:

- branch-only counterparty invisible outside scope;
- direct UUID access denied;
- unauthorized sharing denied;
- client `COUNTERPARTY` portal scope never grants internal CRM access.

Only then implement CRUD.

### 4. Counterparty aggregate

Implement:

- counterparties
- type assignments
- identifiers
- contacts
- structured addresses
- entity commercial profiles
- document preferences/recipients
- billing profiles
- duplicate-check endpoint
- CRM activities

Use optimistic concurrency.

### 5. Service catalog

Implement:

- services
- localizations
- branch/entity availability
- sellable/operational guards

Do not hard-code a country-specific service list in React or backend enums beyond stable service-group/status constants.

### 6. Contract versioning

Implement contract header + immutable contract versions.

Enforce:

- draft mutable;
- approved/active terms not editable in-place;
- active version exact reference;
- superseding preserves history;
- scope authorization;
- applicability service for selected date/entity/client.

Add contract-service terms.

### 7. Deterministic pricing resolver

Implement `PricingResolver` as a domain service.

Resolution precedence exactly:

1. contract negotiated rate
2. client + branch price book
3. client + legal entity price book
4. client generic price book
5. branch price book
6. legal entity price book
7. group/general price book

Within same precedence:
- valid status/date
- matching service/unit/quantity
- highest explicit priority
- unresolved tie -> `AMBIGUOUS_PRICE`

Return full provenance.

Do not silently use first DB row.
Do not invent FX.

### 8. Quotes

Implement:

- quote number via Block 02 sequence service;
- draft lines;
- pricing provenance snapshot;
- service code/name snapshot;
- server-side money calculation;
- quote revision model;
- approval records;
- state machine guards;
- accepted/sent immutability;
- client preference snapshot.

Use decimal/numeric types. Never JS binary floating point for authoritative money calculations.

Do not implement quote-to-Job conversion yet.

### 9. Audit

Critical mutations must produce audit events in the same consistency boundary required by the project architecture.

Audit counterparty scope, contract version transitions, price changes and quote approvals especially.

### 10. Web UI

Implement:

- `/crm/counterparties`
- `/crm/counterparties/:id`
- `/crm/contacts`
- `/crm/activities`
- `/crm/services`
- `/crm/contracts`
- `/crm/price-books`
- `/crm/quotes`

Add permission-aware CRM menu.

All text through i18n keys.

### 11. Price Resolve Test UI

On price-book screen add a resolver test panel that calls the real pricing service and shows:

- selected source
- precedence
- price/currency/unit
- minimum charge
- reason/conditions
- typed error if unresolved

Preview must not create or mutate quote/pricing records.

### 12. Merge OpenAPI

Integrate the Block 03 API fragment into the repository source of truth.
Avoid divergent hand-maintained duplicate contracts.

## Critical invariants

- A counterparty UUID is never authorization.
- Counterparty master is group-level; visibility is explicit/scoped.
- Legal-entity-specific commercial terms do not leak across entities.
- Active contract version is immutable.
- Price selection is deterministic and explainable.
- A tie is an error, never a hidden arbitrary selection.
- Sent/accepted quotes retain snapshots even if master data changes later.
- Server is authoritative for money, status and approval.
- No `MAX()+1`.
- No Job implementation in this block.

## Required tests

At minimum implement all high-risk rows in `TEST_MATRIX.md`, especially:

1. Branch counterparty isolation.
2. Unauthorized direct UUID read.
3. Unauthorized share.
4. Active contract immutability.
5. Contract supersede behavior.
6. Service availability guard.
7. All price precedence levels.
8. Price ambiguity.
9. Missing price.
10. Minimum charge.
11. No fake FX.
12. Browser-manipulated quote total.
13. Quote approval scope.
14. Sent quote immutability.
15. Accepted quote snapshot persistence.
16. End-to-end commercial happy path.

## Completion protocol

Before declaring success run repository equivalents of:

- clean DB migration
- seed
- lint
- typecheck
- unit tests
- authorization integration tests
- pricing tests
- workflow tests
- affected e2e
- production build

Return:

1. changed files;
2. migration/seed changes;
3. endpoints added;
4. screens added;
5. permission changes;
6. tests and exact results;
7. pricing resolver decisions;
8. security/isolation decisions;
9. unresolved business assumptions;
10. exact commands + exit codes.

Do not claim completion while pricing ambiguity, contract immutability, quote calculation or scope-isolation tests are missing/failing.
