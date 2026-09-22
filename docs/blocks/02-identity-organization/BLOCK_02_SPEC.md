# GSI ONE — Implementation Block 02
## Identity + Organization + Localization

**Product:** GSI ONE / GSI ERP  
**Block:** 02  
**PRD baseline:** GSI ERP MASTER PRD v1.0  
**Status:** Ready for Codex implementation  
**Target tasks:** Engineering tasks 11–18 / Epics 003–004  
**Prepared:** 2026-09-22

---

## 1. Objective

Build the security and organizational foundation that every later GSI module will depend on.

At the end of this block, an authenticated user must be able to sign in, receive an effective permission/scope projection, select only organization units they are authorized to access, view the application in a configured language/timezone, and—if authorized—administer legal entities, branches, locations, localization profiles and number sequences.

No Job, Inspection, Laboratory, Report or Finance business logic should be implemented in this block.

---

## 2. Deliverable definition

Block 02 is complete when all of the following are true:

1. OIDC authentication adapter exists and production code does not manage passwords.
2. Development auth stub is available only outside production.
3. `GET /api/v1/me` returns the current user, employee link, effective permissions and effective scopes.
4. Authorization uses **permission + organizational scope + contextual policy**.
5. Group/country/legal-entity/branch/laboratory/counterparty/job-assignment scope types are represented.
6. Branch A users cannot read Branch B data without an explicit broader grant.
7. Organization, legal entity, branch, location and localization administration APIs exist.
8. Language and currency master data are seeded.
9. Branch-level allowed languages are configured as data, not code.
10. Number sequences allocate values safely under concurrency.
11. Admin UI exists for organization hierarchy, localization and access management.
12. Audit events are created for identity status, roles/scopes and organization-master-data changes.
13. API contract and migrations are updated.
14. Lint, typecheck, unit tests, integration tests and affected e2e tests pass.

---

# PART A — DOMAIN MODEL

## 3. Organizational hierarchy

Use this hierarchy:

`Organization / Group → Legal Entity → Branch → Location / Laboratory`

### 3.1 Organization

Represents the GSI group-level reporting boundary.

Required fields:

- `id`
- `code`
- `name`
- `reporting_currency`
- `fiscal_year_start_month`
- `default_language`
- `is_active`
- timestamps + optimistic concurrency version

### 3.2 Legal Entity

Represents a legally registered company that can contract, invoice and own bank/tax configuration.

Required configuration:

- organization
- internal code
- legal name
- optional trading name
- ISO country code
- company registration number
- structured tax identifiers
- registered address
- base currency
- localization profile
- fiscal year start override
- default language
- active date range

**Rule:** deactivating a legal entity never deletes historical records.

### 3.3 Branch

Represents an operational GSI branch/office belonging to one legal entity.

Required configuration:

- legal entity
- branch code
- branch name
- country/city
- IANA timezone
- localization profile
- cost center
- operational email/phone
- allowed languages
- number sequence assignments
- active date range

**Rule:** branch code must be unique inside its legal entity.

### 3.4 Location

A reusable operational place.

Supported initial types:

- `OFFICE`
- `PORT`
- `WAREHOUSE`
- `LAB`
- `CLIENT_SITE`
- `VESSEL_BERTH`
- `OTHER`

A location can be branch-owned or shared, subject to authorization rules.

---

## 4. Identity model

### 4.1 Authentication

Production authentication is delegated to an OIDC/OAuth2 identity provider.

The ERP stores an identity projection, not passwords.

Canonical external identity key:

`(identity_issuer, identity_subject)`

Do **not** assume `sub` alone is globally unique across identity providers.

### 4.2 User lifecycle

Statuses:

- `INVITED`
- `ACTIVE`
- `SUSPENDED`
- `DISABLED`

Behavior:

- `INVITED`: account exists but first successful IdP linkage/login has not completed.
- `ACTIVE`: interactive/API access is permitted by policy.
- `SUSPENDED`: authentication may succeed at IdP, but application access is denied.
- `DISABLED`: account is intentionally deactivated; no interactive access.

### 4.3 Employee linkage

A user may link to one employee record in v1.

Employee contains:

- legal entity
- home branch
- employee number
- name
- job title
- employment status
- hire/termination dates

Authorization is **not** derived solely from the employee's home branch. Access comes from role assignments + scopes.

---

## 5. Authorization model

### 5.1 Effective access formula

`ALLOW = authenticated AND active_user AND permission_granted AND scope_matches AND contextual_policy_allows`

Default is **deny**.

UI visibility is convenience only. API authorization is authoritative.

### 5.2 Permission convention

Use:

`<domain>.<resource>.<action>`

Block 02 seed permissions:

#### Identity / admin

- `admin.user.read`
- `admin.user.manage`
- `admin.role.read`
- `admin.role.manage`
- `admin.permission.read`
- `admin.scope.manage`

#### Organization

- `organization.group.read`
- `organization.group.manage`
- `organization.legal_entity.read`
- `organization.legal_entity.manage`
- `organization.branch.read`
- `organization.branch.manage`
- `organization.location.read`
- `organization.location.manage`
- `organization.localization.read`
- `organization.localization.manage`
- `organization.sequence.read`
- `organization.sequence.manage`

#### Common

- `audit.event.read`

Later blocks add domain-specific permissions.

### 5.3 Scope types

- `GROUP`
- `COUNTRY`
- `LEGAL_ENTITY`
- `BRANCH`
- `LABORATORY`
- `JOB_ASSIGNMENT_ONLY`
- `COUNTERPARTY`

Scope semantics:

| Scope | Meaning |
|---|---|
| GROUP | All data under the organization identified by scope value |
| COUNTRY | Units whose effective country matches ISO-3166 alpha-2 value |
| LEGAL_ENTITY | Specific legal entity plus its branches/locations |
| BRANCH | Specific branch and its owned operational records |
| LABORATORY | Specific laboratory records only |
| JOB_ASSIGNMENT_ONLY | Future Job access only when user is assigned |
| COUNTERPARTY | Client-portal boundary for a single counterparty |

### 5.4 Multiple role assignments

A user can have several role assignments with separate scopes.

Example:

- `Operations Manager` scoped to Kazakhstan branch A
- `Compliance Auditor` scoped group-wide read-only

Effective permissions are the union of active grants; contextual deny rules still apply.

### 5.5 Role assignment validity

Every assignment has:

- `valid_from`
- optional `valid_to`
- creator
- created timestamp

Expired assignments must be ignored automatically.

### 5.6 No implicit superuser bypass

`Group Super Admin` is a role with explicit permissions. Avoid unlogged `isAdmin => allow everything` shortcuts.

Emergency break-glass access, if introduced later, must be a separate audited mechanism.

---

## 6. Standard roles to seed

Seed role templates, but allow administrators to create additional non-system roles later.

For Block 02 create at least:

1. `GROUP_SUPER_ADMIN`
2. `GROUP_CEO_VIEWER`
3. `GROUP_CFO`
4. `GROUP_COO`
5. `GROUP_COMPLIANCE_DIRECTOR`
6. `COUNTRY_DIRECTOR`
7. `BRANCH_MANAGER`
8. `OPERATIONS_MANAGER`
9. `INSPECTOR`
10. `LAB_DIRECTOR`
11. `LAB_ANALYST`
12. `FINANCE_MANAGER`
13. `ACCOUNTANT`
14. `SALES_CRM`
15. `HR_ADMIN`
16. `COMPLIANCE_AUDITOR`
17. `CLIENT_USER`
18. `INTEGRATION_SERVICE`

Only Block 02 permissions should be mapped now. Later migrations extend role/permission maps as modules arrive.

---

# PART B — LOCALIZATION

## 7. Language model

Support BCP-47-compatible language/locale codes.

Initial seed:

- `en`
- `tr`
- `ru`
- `kk`
- `uk`
- `ro`
- `uz`
- `it`
- `ar`

`ar` must set `is_rtl = true`.

Do not assume all branches enable all languages.

### 7.1 Branch language policy

Use a branch-language relation with:

- branch
- language
- `is_ui_enabled`
- `is_document_enabled`
- `is_default`
- display order

Rules:

- exactly one active default branch language;
- default must also be UI-enabled;
- document language may be enabled without being the staff default UI language;
- removing a language from a branch does not destroy historical translated content.

### 7.2 User preference resolution

UI language priority:

1. explicit user preference if allowed;
2. branch default language;
3. legal entity default language;
4. organization default language;
5. `en` fallback.

Timezone resolution:

1. explicit user timezone;
2. selected branch timezone;
3. localization profile timezone;
4. UTC fallback only when no configured value exists.

### 7.3 Translation layers

- UI text: source-controlled message catalogs.
- Master data: `localized_content` table.
- Document templates: later document-template versioning module.
- Free narrative: preserve original; translations are separate.

---

## 8. Localization profiles

Localization profile fields:

- locale/language
- IANA timezone
- date format
- time format
- number format
- first day of week
- settings JSON for non-core display rules

Validation:

- timezone must be a valid IANA timezone at application boundary;
- date/time formats must come from an approved supported set or validated format grammar;
- locale must reference an active language/locale row.

---

## 9. Currency model

Seed at least:

- `EUR`
- `USD`
- `TRY`
- `KZT`
- `UZS`
- `RON`
- `UAH`
- `AED`

The organization defines group reporting currency.
A legal entity defines base currency.

Block 02 does **not** implement accounting or FX valuation. It only provides reference/configuration data required by later finance modules.

---

# PART C — NUMBER SEQUENCES

## 10. Sequence service

Number sequence allocation must be safe under concurrent requests.

Supported reset policies:

- `NEVER`
- `YEARLY`
- `MONTHLY`

Initial document types should be configurable strings, not an application enum that forces redeployment.

Recommended templates:

- Job: `{BRANCH}-{YYYY}-{SEQ}`
- Sample: `S-{BRANCH}-{YY}-{SEQ}`
- Report: `R-{BRANCH}-{YYYY}-{SEQ}`
- Invoice: configured later per legal entity

### 10.1 Allocation algorithm

Allocation must execute inside a database transaction and lock exactly one sequence row using `SELECT ... FOR UPDATE` or equivalent atomic update.

Steps:

1. Load sequence by scope and document type with row lock.
2. Calculate current reset key (`YYYY` or `YYYY-MM`).
3. If reset key changed, set next value to 1 and update reset key.
4. Allocate current value.
5. Increment `next_value`.
6. Render prefix template from validated tokens.
7. Return formatted number.
8. Commit.

Never derive unique document numbers from `COUNT(*)` or max existing row.

### 10.2 Sequence preview

Admin UI may preview the next format but preview must **not reserve** or increment a number.

---

# PART D — API CONTRACT

## 11. Identity endpoints

### `GET /api/v1/me`

Returns:

- user identity projection
- employee/home branch summary
- preferred language/timezone
- effective active role assignments
- flattened effective permissions
- normalized scopes
- selectable legal entities/branches derived from those scopes

Do not return sensitive HR fields.

### `GET /api/v1/me/permissions`

Returns flattened permission codes plus optional source role IDs for debugging/admin UX.

### Admin endpoints

- `GET /api/v1/users`
- `GET /api/v1/users/{id}`
- `PATCH /api/v1/users/{id}`
- `GET /api/v1/roles`
- `POST /api/v1/roles`
- `GET /api/v1/roles/{id}`
- `PATCH /api/v1/roles/{id}`
- `GET /api/v1/permissions`
- `POST /api/v1/users/{id}/role-assignments`
- `DELETE /api/v1/users/{id}/role-assignments/{assignmentId}` or close with `valid_to`

Prefer expiring/revoking assignment over hard deletion once used in audit history.

## 12. Organization endpoints

- `GET /api/v1/organizations`
- `GET /api/v1/organizations/{id}`
- `PATCH /api/v1/organizations/{id}`
- `GET/POST /api/v1/legal-entities`
- `GET/PATCH /api/v1/legal-entities/{id}`
- `GET/POST /api/v1/branches`
- `GET/PATCH /api/v1/branches/{id}`
- `GET/POST /api/v1/locations`
- `GET/PATCH /api/v1/locations/{id}`
- `GET/POST /api/v1/localization-profiles`
- `GET/PATCH /api/v1/localization-profiles/{id}`
- `GET /api/v1/languages`
- `GET /api/v1/currencies`
- `GET/PUT /api/v1/branches/{id}/languages`
- `GET/POST /api/v1/number-sequences`
- `GET/PATCH /api/v1/number-sequences/{id}`
- `POST /api/v1/number-sequences/{id}/preview`

### API behavior

- All list endpoints filter by effective authorization scope.
- Protected resources return 404 where revealing existence itself would cross a tenant/org boundary; use 403 for known in-scope objects when action permission is missing.
- `PATCH` uses optimistic concurrency (`If-Match`/ETag or version).
- Audit-sensitive writes propagate `X-Request-Id`.
- Create operations that may be retried support `Idempotency-Key` where duplication is harmful.

---

# PART E — UI / SCREEN SPECIFICATION

## 13. Global shell

### Organization selector

Top bar shows current:

`Legal Entity / Branch`

Behavior:

- only authorized values are displayed;
- changing branch updates context and cached queries;
- branch selection persists per user/device;
- unauthorized URL/resource remains denied regardless of selector state;
- selector is hidden for users with only one possible branch if desired by UX.

### Language selector

Displays branch-enabled UI languages plus user's currently valid language.

Changing language:

- updates preference;
- updates interface immediately;
- does not mutate stored business data.

---

## 14. `/admin/users`

Table columns:

- Name
- Email
- Status
- Employee
- Home legal entity
- Home branch
- Active roles
- Last login

Filters:

- status
- branch
- role
- search

Actions:

- open user
- suspend/activate when permitted
- assign role
- revoke/expire role assignment

Bulk destructive access changes are out of scope for first implementation.

### User detail

Tabs:

1. Profile
2. Role assignments
3. Effective access
4. Audit history

Effective Access tab must make permission origin explainable:

`permission → role assignment → scope → validity`

---

## 15. `/admin/roles`

Role list:

- code
- name
- system/custom
- active
- assigned users count

Role detail:

- description
- permission matrix grouped by domain
- assignments read view

System roles:

- code cannot be renamed;
- can be deactivated only if business rules explicitly permit it;
- permissions can be changed only by `admin.role.manage` and audited.

---

## 16. `/org/legal-entities`

List columns:

- code
- legal name
- country
- base currency
- default language
- status
- active dates

Create/edit form sections:

1. Identity
2. Registration/tax
3. Address
4. Finance defaults
5. Localization
6. Active dates

Country-specific tax fields stay structured/configurable. Do not hard-code Kazakhstan/Türkiye/etc. form logic in this block.

---

## 17. `/org/branches`

List columns:

- code
- branch name
- legal entity
- country/city
- timezone
- cost center
- default language
- status

Branch detail tabs:

1. General
2. Languages
3. Locations
4. Number sequences
5. Contacts
6. Audit

### Languages tab

Matrix:

| Language | UI | Documents | Default | Order |

Exactly one default language is required for an active branch.

---

## 18. `/org/locations`

Map view is optional for this block; table/form is required.

Fields:

- name/code
- type
- branch owner
- country/city
- structured address
- lat/long optional
- timezone optional
- active state

---

## 19. `/org/localization`

List and edit localization profiles.

Preview area should show sample:

- date
- time
- decimal number
- money amount
- first weekday

This preview is presentation-only.

---

## 20. `/org/sequences`

Columns:

- document type
- scope
- template
- next value
- padding
- reset policy
- last reset key
- active

Actions:

- create
- edit allowed configuration
- preview next formatted value

Directly editing `next_value` requires elevated permission and audit reason, or can be omitted from v1 UI entirely. Recommended: omit manual counter editing in initial release.

---

# PART F — SECURITY / AUDIT

## 21. Required audit events

Create audit events for:

- user status changes
- role creation/update/deactivation
- role permission changes
- user role assignment creation/revocation/expiry edits
- user scope changes
- organization update
- legal entity create/update/deactivate
- branch create/update/deactivate
- branch language policy changes
- localization profile changes
- number sequence configuration changes

Audit record should contain:

- actor user/service
- action code
- target type/id
- organization/legal-entity/branch context where applicable
- before/after diff
- request ID
- timestamp
- reason when required

Never audit raw access tokens.

---

## 22. Negative authorization test matrix

The following are mandatory integration/e2e tests.

### Branch isolation

Given:

- User A has `organization.branch.read` scoped only to Branch A.
- Branch B exists in same or another legal entity.

Then:

- User A can GET Branch A.
- User A cannot GET Branch B.
- Branch B is absent from lists.
- Changing query/body `branchId` manually does not grant access.

### Legal entity scope

User with legal entity scope can see all branches under that entity, but not sibling legal entities.

### Country scope

Country Director can see units in configured country only.

### Group read scope

Group-level viewer can read all organizational units but cannot mutate without `.manage` permission.

### Permission without scope

A user with `organization.branch.manage` permission but no matching scope is denied.

### Scope without permission

A group-scoped user without `organization.branch.manage` cannot mutate branches.

### Expired role assignment

Expired role grants do not contribute permissions/scopes.

### Suspended user

Suspended application user receives access denial even with valid OIDC token.

### Client role

Client user never gains internal organization admin visibility from counterparty scope.

---

# PART G — IMPLEMENTATION STRUCTURE

## 23. Recommended modules

### API

```text
apps/api/src/modules/
  identity/
    application/
    domain/
    infrastructure/
    presentation/
  authorization/
    policies/
    guards/
    decorators/
  organization/
  localization/
  audit/
```

### Web

```text
apps/web/src/
  app/(authenticated)/admin/users/
  app/(authenticated)/admin/roles/
  app/(authenticated)/org/group/
  app/(authenticated)/org/legal-entities/
  app/(authenticated)/org/branches/
  app/(authenticated)/org/locations/
  app/(authenticated)/org/localization/
  app/(authenticated)/org/sequences/
  features/auth/
  features/organization/
  features/localization/
```

### Shared packages

```text
packages/
  auth/
  api-client/
  i18n/
  validation/
  ui/
```

Do not place domain policy in React components.

---

## 24. Suggested implementation order

### Phase 02A — Identity adapter

1. OIDC config validation.
2. JWT verification / auth guard.
3. Dev auth provider gated from production.
4. User projection lookup/upsert policy.
5. `GET /me`.

### Phase 02B — Authorization engine

6. Roles/permissions repository.
7. Active role assignment resolution.
8. Scope normalization.
9. policy service / guard.
10. negative branch-isolation tests.

### Phase 02C — Organization master data

11. organization/legal entity APIs.
12. branch APIs.
13. location APIs.
14. optimistic concurrency.
15. audit integration.

### Phase 02D — Localization

16. seed languages/currencies.
17. localization profiles.
18. branch language policy.
19. user language/timezone preferences.
20. i18n shell integration.

### Phase 02E — Number sequences

21. sequence CRUD.
22. concurrency-safe allocation service.
23. preview service.
24. concurrency integration test.

### Phase 02F — Admin UI

25. organization selector.
26. legal entity screens.
27. branch screens.
28. localization screens.
29. users/roles screens.
30. accessibility and responsive review.

---

# PART H — ACCEPTANCE CRITERIA

## 25. Functional acceptance

- [ ] Production auth uses OIDC and stores no passwords.
- [ ] `/me` returns effective permission + scope data.
- [ ] User can only select authorized branches.
- [ ] Branch list/API is scope filtered.
- [ ] Admin can create legal entity, branch and location with required permissions.
- [ ] Admin can configure branch allowed/default languages.
- [ ] User can change preferred UI language.
- [ ] Branch timezone is rendered correctly in UI.
- [ ] Active branch requires one default UI language.
- [ ] Currency and language reference lists are available.
- [ ] Number sequence allocation is unique under parallel requests.
- [ ] Every critical admin change is audited.
- [ ] Suspended users are denied even with valid external token.

## 26. Technical acceptance

- [ ] strict TypeScript passes.
- [ ] no `any` in new domain/application code.
- [ ] OpenAPI updated and valid.
- [ ] DB migration applies cleanly to fresh DB.
- [ ] seed is idempotent or safely repeatable.
- [ ] API validates UUIDs, country/currency/language values and timezone.
- [ ] ETag/version conflict returns 409/412 as chosen by project convention.
- [ ] integration tests cover branch isolation.
- [ ] test covers expired role assignment.
- [ ] test covers concurrent number allocation.
- [ ] no secrets/tokens appear in logs.
- [ ] lint/typecheck/tests/build pass.

---

# PART I — OUT OF SCOPE FOR BLOCK 02

Do not implement yet:

- Counterparties/contracts
- Jobs
- Inspector scheduling
- Inspection forms
- Media evidence
- Samples/chain of custody
- LIMS
- Report generation
- Accreditation engine
- Invoicing/accounting
- Valuation
- Client portal business screens

However, authorization and organization abstractions must be designed so these later modules can use them without redesign.

---

## 27. Definition of Done for Codex

Codex must not say Block 02 is finished until it provides:

1. changed-file summary;
2. migration summary;
3. API endpoints added/changed;
4. authorization policy summary;
5. tests added;
6. commands run and exact results;
7. unresolved decisions/assumptions;
8. confirmation that no later domain modules were implemented prematurely.
