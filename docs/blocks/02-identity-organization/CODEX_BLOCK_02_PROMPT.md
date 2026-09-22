# Codex Task Prompt — GSI ONE Block 02

You are implementing **Block 02: Identity + Organization + Localization** for GSI ONE.

Read these files before coding:

1. `CODEX_SYSTEM_PROMPT.md`
2. `GSI_ERP_MASTER_PRD_v1.0.md`
3. `BLOCK_02_SPEC.md`
4. `schema.sql`
5. `001_identity_org_localization.sql`
6. `seed_identity_org_localization.sql`
7. `openapi.yaml`
8. `openapi.identity-org-localization.yaml`

## Goal

Implement only the identity, authorization, organization, localization and number-sequence foundation described in Block 02.

Do not implement CRM, Jobs, inspections, samples, laboratory, reports, finance or valuation yet.

## Mandatory implementation order

### 1. Database

- Integrate Block 02 schema changes into the project's migration system.
- Add idempotent seed logic for languages, currencies, countries, permissions and role templates.
- Preserve existing data and migration history.

### 2. OIDC authentication

- Add production OIDC/JWT validation through an adapter boundary.
- Identify users by `(issuer, subject)`.
- Add a development auth provider only when environment explicitly allows it.
- Production startup must fail or disable dev auth if dev auth is configured incorrectly.
- Never store application passwords.

### 3. Current-user projection

Implement:

- `GET /api/v1/me`
- `GET /api/v1/me/permissions`

Resolve only active, non-revoked, in-validity-window role assignments.
Return normalized permission codes and scopes.

### 4. Authorization policy engine

Implement an explicit authorization service with default deny semantics.

Effective access:

`authenticated + active user + permission + matching scope + contextual policy`

Required scope resolution:

- GROUP
- COUNTRY
- LEGAL_ENTITY
- BRANCH
- LABORATORY
- JOB_ASSIGNMENT_ONLY placeholder policy boundary
- COUNTERPARTY placeholder policy boundary

Do not create a magical `isAdmin` bypass.

### 5. Negative isolation tests

Before organization admin UI, create integration tests proving:

- Branch A user cannot list/read Branch B.
- Query/body tampering with another branch ID is denied.
- Permission without scope is denied.
- Scope without permission is denied.
- Expired/revoked assignment is ignored.
- Suspended user is denied even with a cryptographically valid token.

### 6. Organization API

Implement authorized CRUD/read endpoints from Block 02 for:

- organizations
- legal entities
- branches
- locations
- localization profiles
- branch language configuration
- languages
- currencies
- number sequences

Use optimistic concurrency on mutable aggregates.

### 7. Number sequence service

Implement concurrency-safe allocation using a DB transaction and row-level lock/atomic equivalent.

Add a test with parallel allocators asserting:

- no duplicate values;
- no missing committed allocations caused by races;
- reset policy behaves correctly at year/month boundary using injected clock.

Preview must not increment the sequence.

### 8. Audit

Audit:

- user status changes
- role/permission changes
- assignments/scopes
- legal entities
- branches
- branch languages
- locations
- localization profiles
- sequence configuration

Critical write + audit/outbox must be in one DB transaction where the project architecture requires it.

### 9. Web admin UI

Implement permission-aware screens:

- `/admin/users`
- `/admin/roles`
- `/org/group`
- `/org/legal-entities`
- `/org/branches`
- `/org/locations`
- `/org/localization`
- `/org/sequences`

Implement global organization/branch selector and language selector.

All UI strings must use i18n keys. Ensure layouts do not structurally break in RTL.

### 10. API contract

Merge the Block 02 API fragment into the main OpenAPI contract or its generated source of truth.

Do not leave divergent duplicate contracts.

## Important business rules

- Countries/branches/languages/currencies are data, never hard-coded UI logic.
- Active branch must have one default UI language before it is considered operationally configured.
- User-selected branch is a UX context, never an authorization grant.
- Legal entity deactivation is non-destructive.
- Historical translations remain even when a language is no longer enabled for new use.
- Production does not authenticate against local plaintext/password tables.
- `sub` is not globally unique without OIDC issuer.

## Expected tests

At minimum:

1. `/me` happy path.
2. `/me` suspended user.
3. expired role assignment ignored.
4. revoked assignment ignored.
5. branch isolation list.
6. branch isolation direct read.
7. branch tampering on create/update.
8. legal entity scope includes child branches.
9. country scope only resolves matching country.
10. group read does not imply manage.
11. branch language exactly-one-default validation.
12. invalid timezone rejected.
13. optimistic concurrency conflict.
14. number sequence parallel allocation.
15. sequence preview does not increment.
16. audit event created for role/scope change.

## Completion protocol

Before declaring success, run repository equivalents of:

- install/dependency validation
- database migration from clean database
- seed
- lint
- typecheck
- unit tests
- authorization integration tests
- affected e2e tests
- production build

Then provide:

1. files changed;
2. migrations added;
3. endpoints added;
4. screens added;
5. tests added and results;
6. security decisions;
7. unresolved assumptions;
8. exact commands and exit results.

Do not claim completion if authorization isolation tests are missing or failing.
