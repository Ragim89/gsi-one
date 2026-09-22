# GSI ONE — Implementation Block 03
## Counterparties + CRM + Contacts + Contracts + Pricing + Client Preferences

**Version:** 1.0  
**Depends on:** Block 01 Repository Bootstrap, Block 02 Identity + Organization + Localization  
**Next block:** Block 04 Job / Inspection Order Core

---

## 1. Objective

Block 03 creates the complete commercial master-data layer required before operational Jobs can be created safely.

The block must make it possible to answer, deterministically and auditably:

- Who is the counterparty?
- Which GSI legal entity/branch is allowed to work with it?
- Which contacts represent it?
- Which contract/version governs the work?
- Which services can be sold by the selected GSI entity/branch?
- Which price applies on a specific date, for a specific client, service, unit and quantity?
- Which client-specific billing/document/language preferences must follow into a future Job?
- Which quote was approved and accepted?
- Which exact commercial terms must be snapshotted into the Job so later master-data edits cannot rewrite history?

Block 03 is not a generic CRM. It is the commercial source of truth that feeds Job creation, reports and finance.

---

## 2. Deliverable definition

At completion the system must support:

1. Group-level counterparty master records with controlled scope visibility.
2. Multiple counterparty roles: client, supplier, agent, subcontractor, external laboratory, carrier, broker, other.
3. Structured identifiers, tax registrations, addresses and contacts.
4. GSI-entity-specific commercial profiles for the same counterparty.
5. Client-specific languages, document distribution and billing preferences.
6. Service catalog with local availability per legal entity/branch.
7. Versioned contracts with immutable activated versions.
8. Contract-specific service terms.
9. Price books with deterministic resolution and effective dates.
10. Quotes with server-side calculations, approval workflow and immutable accepted commercial snapshots.
11. CRM activities/notes sufficient for account context.
12. Authorization using Block 02 permissions/scopes.
13. Full audit trail and optimistic concurrency.
14. API + web UI + integration tests.
15. A clean handoff surface for Block 04 Job creation.

---

# PART A — DOMAIN MODEL

## 3. Counterparty aggregate

### 3.1 Counterparty master

`counterparties` is the organization-wide identity of a company/person GSI does business with.

Core fields:

- `id`
- `organization_id`
- `code`
- `legal_name`
- `trading_name`
- `country_code`
- `preferred_language`
- `default_currency`
- `status`
- `risk_status`
- `is_active`
- audit/version fields

A counterparty must not be duplicated separately for every GSI branch.

Example:

`ACME Grain Trading Ltd` is one counterparty master even if GSI Türkiye, Kazakhstan and Romania all work with it.

Entity-specific commercial differences belong in `counterparty_entity_profiles`.

### 3.2 Counterparty types

Use normalized assignments rather than treating a single type as exclusive.

Supported seed codes:

- `CLIENT`
- `SUPPLIER`
- `AGENT`
- `SUBCONTRACTOR`
- `EXTERNAL_LAB`
- `CARRIER`
- `BROKER`
- `WAREHOUSE_OPERATOR`
- `OTHER`

One counterparty may be both `CLIENT` and `SUPPLIER`.

### 3.3 Counterparty identifiers

Identifiers must be structured, not buried only in JSON.

Examples:

- company registration number
- tax/VAT number
- national business identifier
- customs identifier
- internal legacy code

`counterparty_identifiers` fields:

- `counterparty_id`
- `identifier_type`
- `country_code`
- `value`
- `normalized_value`
- `is_primary`
- validity/status metadata

Duplicate detection should warn when the same normalized identifier is already assigned to another active counterparty.

Do not automatically merge records.

### 3.4 Visibility scopes

Counterparty master data is not automatically visible to every employee in the group.

Use `counterparty_scopes`:

- `GROUP`
- `COUNTRY`
- `LEGAL_ENTITY`
- `BRANCH`

Rules:

1. A newly created counterparty receives the creator's active organizational scope as an explicit visibility record unless the caller has group-sharing permission.
2. A contract with a legal entity automatically requires/creates legal-entity visibility.
3. A quote owned by a branch automatically requires/creates visibility to that branch/legal entity according to policy.
4. Users never gain access merely because they know the UUID.
5. Client portal users use Block 02 `COUNTERPARTY` scope and never receive internal CRM visibility.

The authorization engine must combine:
`permission + user org scope + counterparty visibility + contextual policy`.

### 3.5 Entity-specific commercial profile

`counterparty_entity_profiles` stores how one GSI legal entity treats the counterparty.

Examples:

- account manager
- customer/vendor account code
- default currency
- payment terms
- credit days
- PO required
- billing consolidation preference
- tax handling hints
- commercial status
- credit hold
- default branch
- invoice contact

This prevents a Kazakhstan-specific payment term from incorrectly affecting Türkiye.

---

## 4. Contacts

A contact belongs to a counterparty.

Fields:

- full name
- job title
- department
- email
- phone
- preferred language
- timezone
- primary flag
- active flag
- communication consent/settings
- notes metadata

Rules:

- At most one active primary contact per counterparty.
- Multiple billing/report recipients are allowed.
- Contact deactivation is non-destructive.
- Email comparison should be case-insensitive.
- Contact visibility follows the counterparty.
- Client portal identity linking is not implemented here; Block 02 `COUNTERPARTY` scope remains the boundary.

---

## 5. Addresses

Structured address fields:

- type
- line 1
- line 2
- city
- region/state
- postal code
- country
- latitude/longitude optional
- is default
- label
- external reference metadata

Types:

- `REGISTERED`
- `BILLING`
- `SHIPPING`
- `SITE`
- `WAREHOUSE`
- `PORT`
- `OTHER`

Do not require geocoordinates.

The legacy JSON address field may remain temporarily for migration compatibility, but new application code should use structured columns.

---

## 6. CRM activities

Implement a minimal account activity timeline, not a full sales automation suite.

`crm_activities` supports:

- `NOTE`
- `CALL`
- `EMAIL`
- `MEETING`
- `TASK`
- `FOLLOW_UP`

It can be linked to:

- counterparty
- contact
- contract
- quote

Fields:

- activity type
- subject
- body
- occurred/due timestamp
- status
- owner
- participants metadata
- created/updated audit

Do not implement email sending in Block 03.

Opportunity pipeline is explicitly deferred.

---

# PART B — CLIENT PREFERENCES

## 7. Document preferences

Document/report behavior must be configurable by counterparty and, where necessary, GSI legal entity.

`counterparty_document_preferences`:

- `counterparty_id`
- optional `legal_entity_id`
- `document_type`
- primary language
- additional language list
- filename pattern
- portal delivery enabled
- email delivery enabled
- automatic delivery after approval
- preferred template key (future document-engine binding)
- settings JSON for non-core future options

Suggested document types:

- `COMMERCIAL_OFFER`
- `INSPECTION_REPORT`
- `LAB_REPORT`
- `CERTIFICATE`
- `INVOICE`
- `CREDIT_NOTE`
- `OTHER`

Rules:

- Language codes must exist in Block 02 `languages`.
- Future Job/report issuance must snapshot the resolved preference.
- Changing a preference does not change an already issued/accepted document.
- Template keys are configuration references, not hard-coded UI logic.

## 8. Document recipients

Recipients are normalized through `counterparty_document_recipients`.

Each preference can target multiple active contacts.

Recipient purpose:

- `TO`
- `CC`
- `BCC`

Block 03 stores configuration only. Sending is implemented later by the communications/document blocks.

## 9. Billing profiles

`counterparty_billing_profiles` are legal-entity specific.

Fields include:

- currency
- payment term days
- PO required
- consolidated invoicing
- billing address
- invoice contact
- tax registration/label metadata
- client invoice reference requirement
- credit limit optional
- credit hold

Finance remains out of scope, but future Job/Invoice modules consume these settings.

---

# PART C — SERVICE CATALOG

## 10. Service master

`service_catalog` is the canonical list of sellable/operational services.

Examples are configuration, not code.

Fields:

- code
- canonical name
- service group
- default unit
- `requires_inspection`
- `requires_sampling`
- `requires_lab`
- `requires_report`
- active dates
- settings
- version/audit

Possible service groups:

- `INSPECTION`
- `SAMPLING`
- `LABORATORY`
- `SUPERVISION`
- `WEIGHING`
- `FUMIGATION`
- `STOCK_MONITORING`
- `CMA`
- `OTHER`

The actual GSI commercial catalog must be approved by GSI business owners before production seeding.

### 10.1 Localized service names

Use `service_localizations`:

- service
- language code
- name
- short name
- description

Never duplicate service IDs by language.

### 10.2 Service availability

Use `service_availability` so a service can be enabled/disabled by:

- legal entity
- branch

Fields:

- service
- legal entity
- optional branch
- sellable flag
- operational flag
- effective dates
- local default unit
- settings

A service unavailable to a selected legal entity/branch must not be quoted or placed on a new Job without elevated override.

---

# PART D — CONTRACTS

## 11. Contract aggregate

`contracts` identifies the agreement:

- counterparty
- GSI legal entity
- contract number
- title
- status
- currency
- high-level dates
- audit/version

Statuses:

`DRAFT → ACTIVE → SUSPENDED / EXPIRED / TERMINATED`

A contract is not deleted after commercial use.

### 11.1 Contract versions

Terms must be versioned.

`contract_versions` contains immutable commercial/operational terms for a version:

- version number
- effective from/to
- signed date
- signed by GSI / counterparty metadata
- billing terms
- operational terms
- client requirements
- governing law/jurisdiction text
- source file reference metadata
- status
- approval metadata
- created audit

States:

- `DRAFT`
- `PENDING_APPROVAL`
- `APPROVED`
- `ACTIVE`
- `SUPERSEDED`
- `REJECTED`

Rules:

1. Draft version is mutable.
2. Approved/active version becomes immutable except explicit correction workflow.
3. Activating a version supersedes the previous active version for overlapping applicability.
4. Historical Jobs reference the exact `contract_version_id`.
5. Date overlap for two ACTIVE versions of the same contract is rejected unless business rule explicitly allows it.
6. Termination does not delete history.

### 11.2 Contract services

`contract_services` links a contract version to services and optional commercial constraints:

- service
- preferred unit
- minimum charge
- negotiated unit price optional
- price book optional
- SLA metadata
- client instructions
- effective scope/conditions

If a negotiated contract rate exists, it is considered before generic price-book rates.

---

# PART E — PRICING

## 12. Price books

Price books are effective-dated commercial rate collections.

A price book may apply to:

- group/general
- legal entity
- branch
- counterparty

Fields:

- name
- status
- currency
- legal entity
- branch
- counterparty
- valid from/to
- priority
- version/audit

Statuses:

- `DRAFT`
- `ACTIVE`
- `RETIRED`

Only ACTIVE books are used by automatic pricing.

### 12.1 Price book items

Each item contains:

- service
- unit
- pricing method
- unit price
- minimum charge
- optional quantity range
- optional conditions
- audit/version

Pricing methods initially:

- `FIXED`
- `PER_UNIT`

Future methods such as tiered/percentage/custom can be added later.

### 12.2 Deterministic resolution order

For a pricing request with:

`date + legal entity + branch + counterparty + service + unit + quantity + contract version`

resolve in this order:

1. explicit negotiated rate on active applicable `contract_service`
2. counterparty + branch price book
3. counterparty + legal entity price book
4. counterparty generic price book
5. branch price book
6. legal entity price book
7. group/general price book

Within the same precedence:

1. active and date-valid only
2. service/unit/quantity must match
3. highest explicit priority wins
4. if two candidates remain at the same precedence and priority, return `AMBIGUOUS_PRICE` — do not silently choose one

Resolution returns:

- price
- currency
- unit
- minimum charge
- pricing source type
- pricing source ID
- matched conditions
- resolution timestamp

Every quote item stores this pricing provenance snapshot.

### 12.3 Currency policy

Automatic pricing should normally produce quote lines in the price source currency.

If the quote requires another currency:

- use an explicit user-entered negotiated price, or
- invoke the shared exchange-rate service when implemented/configured.

Block 03 must never invent an FX rate.

---

# PART F — QUOTES

## 13. Quote lifecycle

Statuses:

`DRAFT → PENDING_APPROVAL → APPROVED → SENT → ACCEPTED / REJECTED / EXPIRED`

`CONVERTED` is reserved for Block 04 when a Job is created.

Rules:

- DRAFT lines are editable.
- Submission recalculates totals server-side.
- Approval records approver, timestamp and decision.
- SENT locks commercial fields except through a revision workflow.
- ACCEPTED is immutable commercial evidence.
- Expired quotes cannot be accepted without authorized reactivation/revision.
- Rejection requires optional reason.
- Conversion to Job is not implemented until Block 04.

### 13.1 Quote numbering

Use Block 02 sequence service.

Suggested document type: `QUOTE`.

Do not generate quote numbers with `MAX()+1`.

### 13.2 Quote items

Quote item snapshots:

- service ID
- service code/name snapshot
- description
- quantity
- unit
- unit price
- minimum charge applied
- discount
- tax code/rate snapshot where used
- line subtotal
- tax amount
- total
- pricing source type/ID
- pricing resolution JSON

Quote totals are calculated server-side using decimal/numeric arithmetic.

### 13.3 Approval policy

Block 03 provides the approval mechanism, even if initial policy is simple.

`quote_approvals`:

- quote
- step
- approver
- decision
- decision timestamp
- comment

Minimum initial triggers:

- explicit approval required before status `APPROVED`
- discount beyond configured threshold may require a user with `crm.quote.discount_approve`
- users cannot approve their own quote when four-eyes policy is enabled in organization settings

Policy values must be configuration, not hard-coded by country.

### 13.4 Quote revisions

Use `quote_revisions` to preserve commercial history after sending.

Revision rules:

- Accepted quote is never overwritten.
- Creating a revision clones the quote into a new revision state.
- Previous sent/expired/rejected revision remains readable.
- Revision number starts at 1.
- Block 04 references the accepted revision.

---

# PART G — PERMISSIONS AND AUTHORIZATION

## 14. Permission codes

Add:

### Counterparties

- `crm.counterparty.read`
- `crm.counterparty.create`
- `crm.counterparty.manage`
- `crm.counterparty.share`
- `crm.counterparty.identifiers.manage`
- `crm.counterparty.preferences.manage`

### Contacts / activities

- `crm.contact.read`
- `crm.contact.manage`
- `crm.activity.read`
- `crm.activity.manage`

### Services

- `crm.service.read`
- `crm.service.manage`
- `crm.service.availability_manage`

### Contracts

- `crm.contract.read`
- `crm.contract.create`
- `crm.contract.manage`
- `crm.contract.approve`
- `crm.contract.activate`

### Pricing

- `crm.price_book.read`
- `crm.price_book.manage`
- `crm.price.resolve`

### Quotes

- `crm.quote.read`
- `crm.quote.create`
- `crm.quote.manage`
- `crm.quote.approve`
- `crm.quote.discount_approve`
- `crm.quote.send`
- `crm.quote.accept`

## 15. Role recommendations

Existing Block 02 role templates receive permissions approximately as follows:

- **Group Admin** — full Block 03 administration within granted scope.
- **Country Director** — read/manage counterparties, contracts, pricing, quotes for country scope; approvals according to policy.
- **Branch Manager** — branch commercial data, quote approval according to limits.
- **Sales/CRM** — counterparties, contacts, activities, quotes, contracts; price-book read; limited manage according to assignment.
- **Operations Manager** — counterparty/contact/contract/service read; quote read; no pricing administration by default.
- **Finance Manager** — counterparty billing profile/contract/quote read; credit settings where explicitly granted.
- **Client User** — no internal CRM screens; portal data remains bounded by `COUNTERPARTY` scope and dedicated future portal permissions.

Permissions are templates only. Effective access still requires matching Block 02 scope.

## 16. Authorization rules

Examples:

- Branch A Sales user cannot discover a Branch B-only counterparty.
- Knowing counterparty UUID does not bypass visibility.
- Legal Entity A user cannot activate a contract owned by Legal Entity B.
- Price resolution must filter sources by authorized ownership before returning provenance.
- A user with `crm.quote.approve` but no scope to the quote's owner branch cannot approve it.
- Client portal scope must never expose internal notes, price-book administration, margins, approval comments or other counterparties.

Default deny.

---

# PART H — API CONTRACT

## 17. Counterparty API

### Counterparties

- `GET /api/v1/counterparties`
- `POST /api/v1/counterparties`
- `GET /api/v1/counterparties/{id}`
- `PATCH /api/v1/counterparties/{id}`
- `POST /api/v1/counterparties/{id}/deactivate`
- `GET /api/v1/counterparties/{id}/duplicate-check`

### Types / identifiers / scopes

- `GET /api/v1/counterparties/{id}/types`
- `PUT /api/v1/counterparties/{id}/types`
- `GET /api/v1/counterparties/{id}/identifiers`
- `POST /api/v1/counterparties/{id}/identifiers`
- `PATCH /api/v1/counterparties/{id}/identifiers/{identifierId}`
- `GET /api/v1/counterparties/{id}/scopes`
- `POST /api/v1/counterparties/{id}/scopes`
- `DELETE /api/v1/counterparties/{id}/scopes/{scopeId}`

### Contacts / addresses

- `GET /api/v1/counterparties/{id}/contacts`
- `POST /api/v1/counterparties/{id}/contacts`
- `PATCH /api/v1/contacts/{contactId}`
- `GET /api/v1/counterparties/{id}/addresses`
- `POST /api/v1/counterparties/{id}/addresses`
- `PATCH /api/v1/addresses/{addressId}`

### Profiles and preferences

- `GET /api/v1/counterparties/{id}/entity-profiles`
- `PUT /api/v1/counterparties/{id}/entity-profiles/{legalEntityId}`
- `GET /api/v1/counterparties/{id}/document-preferences`
- `PUT /api/v1/counterparties/{id}/document-preferences/{documentType}`
- `GET /api/v1/counterparties/{id}/billing-profiles`
- `PUT /api/v1/counterparties/{id}/billing-profiles/{legalEntityId}`

## 18. CRM activity API

- `GET /api/v1/crm/activities`
- `POST /api/v1/crm/activities`
- `PATCH /api/v1/crm/activities/{id}`

## 19. Service API

- `GET /api/v1/services`
- `POST /api/v1/services`
- `GET /api/v1/services/{id}`
- `PATCH /api/v1/services/{id}`
- `GET /api/v1/services/{id}/localizations`
- `PUT /api/v1/services/{id}/localizations/{languageCode}`
- `GET /api/v1/services/{id}/availability`
- `PUT /api/v1/services/{id}/availability`

## 20. Contract API

- `GET /api/v1/contracts`
- `POST /api/v1/contracts`
- `GET /api/v1/contracts/{id}`
- `PATCH /api/v1/contracts/{id}`
- `POST /api/v1/contracts/{id}/versions`
- `GET /api/v1/contracts/{id}/versions`
- `GET /api/v1/contracts/{id}/versions/{versionId}`
- `PATCH /api/v1/contracts/{id}/versions/{versionId}`
- `POST /api/v1/contracts/{id}/versions/{versionId}/submit`
- `POST /api/v1/contracts/{id}/versions/{versionId}/approve`
- `POST /api/v1/contracts/{id}/versions/{versionId}/activate`
- `POST /api/v1/contracts/{id}/suspend`
- `POST /api/v1/contracts/{id}/terminate`

## 21. Pricing API

- `GET /api/v1/price-books`
- `POST /api/v1/price-books`
- `GET /api/v1/price-books/{id}`
- `PATCH /api/v1/price-books/{id}`
- `POST /api/v1/price-books/{id}/items`
- `PATCH /api/v1/price-books/{id}/items/{itemId}`
- `POST /api/v1/price-books/{id}/activate`
- `POST /api/v1/price-books/{id}/retire`
- `POST /api/v1/pricing/resolve`

`POST /pricing/resolve` must return explainable provenance or a typed failure:

- `NO_PRICE`
- `AMBIGUOUS_PRICE`
- `SERVICE_NOT_AVAILABLE`
- `INVALID_UNIT`
- `OUTSIDE_VALIDITY`

## 22. Quote API

- `GET /api/v1/quotes`
- `POST /api/v1/quotes`
- `GET /api/v1/quotes/{id}`
- `PATCH /api/v1/quotes/{id}`
- `POST /api/v1/quotes/{id}/items`
- `PATCH /api/v1/quotes/{id}/items/{itemId}`
- `DELETE /api/v1/quotes/{id}/items/{itemId}`
- `POST /api/v1/quotes/{id}/recalculate`
- `POST /api/v1/quotes/{id}/submit`
- `POST /api/v1/quotes/{id}/approve`
- `POST /api/v1/quotes/{id}/send`
- `POST /api/v1/quotes/{id}/accept`
- `POST /api/v1/quotes/{id}/reject`
- `POST /api/v1/quotes/{id}/revisions`

Reserve but do not implement in Block 03:

- `POST /api/v1/quotes/{id}/convert-to-job`

That endpoint belongs to Block 04.

---

# PART I — UI / SCREEN SPECIFICATION

## 23. CRM navigation

Add the commercial section:

- Counterparties
- Contacts
- Activities
- Services
- Contracts
- Price Books
- Quotes

Menu visibility is permission-aware.

## 24. `/crm/counterparties`

List columns:

- code
- legal/trading name
- country
- types
- commercial status
- visible GSI entities/branches summary
- preferred language
- default currency
- account manager
- active status

Filters:

- name/code
- type
- country
- legal entity
- branch
- account manager
- status
- active/inactive

Actions:

- create
- export permitted fields
- deactivate
- open detail

Create flow includes duplicate warning before submit.

## 25. `/crm/counterparties/:id`

Tabs:

1. Overview
2. Legal & Identifiers
3. Contacts
4. Addresses
5. GSI Relationships
6. Contracts
7. Pricing
8. Document Preferences
9. Billing Profiles
10. Activities
11. Jobs — placeholder/read-only until Block 04
12. Audit

Overview cards:

- status/type
- country/language/currency
- account owner
- active contracts
- active quote count
- credit hold indicator
- configured report/invoice languages

## 26. `/crm/contacts`

Directory with:

- person
- company
- title
- email
- phone
- language
- primary flag
- active flag

Scope filtering must happen server-side.

## 27. `/crm/activities`

Timeline/list with filters:

- owner
- counterparty
- type
- due/overdue
- status

Do not expose internal activities to client portal users.

## 28. `/crm/services`

Service list and detail:

- code
- localized name
- group
- default unit
- workflow flags
- active period
- enabled legal entities/branches

Tabs:

- General
- Languages
- Availability
- Audit

## 29. `/crm/contracts`

List:

- contract number
- counterparty
- GSI legal entity
- status
- active version
- effective dates
- currency
- expiry warning

Detail:

- Summary
- Versions
- Services
- Client Requirements
- Commercial Terms
- Audit

Version editor must visibly distinguish DRAFT from immutable ACTIVE version.

## 30. `/crm/price-books`

List:

- name
- owner legal entity/branch
- counterparty
- currency
- validity
- priority
- status

Detail:

- header
- items grid
- effective scope
- audit
- **Resolve Test** panel

Resolve Test lets an authorized user input:
date, client, branch, service, unit, quantity, optional contract
and see which source would win and why.

Preview never creates a quote.

## 31. `/crm/quotes`

List:

- quote number
- revision
- client
- legal entity
- branch
- currency
- total
- status
- validity
- owner

Quote wizard:

1. GSI entity/branch
2. client
3. contract/version optional
4. service lines
5. pricing resolution
6. discount/tax
7. commercial notes
8. review
9. submit

Quote detail:

- Overview
- Lines
- Pricing provenance
- Approval history
- Client preferences snapshot preview
- Revisions
- Audit

No Job tab/action until Block 04 except disabled placeholder.

---

# PART J — VALIDATION AND BUSINESS RULES

## 32. Counterparty validation

- Legal name required.
- Organization required.
- Preferred language must exist if set.
- Default currency must exist if set.
- Duplicate identifier produces blocking conflict when identifier type is configured unique.
- Duplicate name/country produces warning, not automatic block.
- Inactive counterparty cannot be selected for new quote unless override permission exists.

## 33. Contract validation

- Legal entity and counterparty must be mutually visible/authorized.
- Contract number unique inside legal entity.
- Active contract version requires approved state and valid effective dates.
- Cannot mutate active version terms in-place.
- Terminated contract cannot be newly selected for quote/Job after termination date.

## 34. Price-book validation

- Active price book requires currency.
- `valid_to >= valid_from`.
- Branch must belong to selected legal entity when both are set.
- Counterparty must be visible to owner scope.
- Quantity max must be >= min.
- Unit price/minimum charge cannot be negative.
- Overlapping equal-precedence/equal-priority rules are allowed only if conditions make them mutually exclusive; otherwise activation fails or pricing resolver returns ambiguity.

## 35. Quote validation

- Active client required.
- Selected branch belongs to legal entity.
- Service available for branch/entity.
- Contract/version valid for selected client/entity/date.
- All money calculations server-side.
- Accepted/sent immutable except revision operation.
- Approval decision must be audited.
- Stale version update returns optimistic concurrency conflict.

---

# PART K — AUDIT AND SECURITY

## 36. Required audit events

Audit at minimum:

- counterparty create/update/deactivate/reactivate
- identifier add/change
- type assignment
- visibility scope add/remove
- entity profile and billing profile change
- contact create/change/deactivate
- document preference change
- service/catalog/availability change
- contract create/update
- contract version submit/approve/activate/supersede
- contract suspend/terminate
- price-book create/change/activate/retire
- price item change
- quote create/change/submit/approve/send/accept/reject/revision
- discount approval
- pricing resolution used to commit a quote line

Audit includes:

- actor
- request/correlation ID
- timestamp
- entity type/id
- before/after or meaningful diff
- reason where required
- source channel

## 37. Sensitive information

- Do not put secrets in CRM notes.
- PII in contacts is accessible only to authorized users.
- API logs must not dump full contact/billing payloads by default.
- Export endpoints must apply the same field and row authorization as screen/API reads.
- No sequential IDs in public URLs.
- Use UUIDs and server-side authorization.

---

# PART L — DATABASE CHANGES

## 38. New/extended tables

Migration file `002_commercial_crm.sql` extends the baseline schema with:

- `counterparty_type_catalog`
- `counterparty_type_assignments`
- `counterparty_identifiers`
- `counterparty_scopes`
- `counterparty_entity_profiles`
- `counterparty_document_preferences`
- `counterparty_document_recipients`
- `counterparty_billing_profiles`
- structured counterparty address fields
- hardened contacts
- `crm_activities`
- `service_localizations`
- `service_availability`
- `contract_versions`
- `contract_services`
- `price_books` hardening
- `price_book_items` hardening
- `quote_revisions`
- `quote_approvals`
- quote/quote-item snapshot fields

Do not create a second competing counterparty master.

---

# PART M — IMPLEMENTATION STRUCTURE

## 39. API modules

Recommended NestJS modules:

```text
apps/api/src/modules/
  crm/
    counterparties/
    contacts/
    activities/
    client-preferences/
  commercial/
    services/
    contracts/
    pricing/
    quotes/
```

Shared domain services:

```text
packages/
  authorization/
  money/
  localization/
  audit/
  contracts/
  pricing/
```

Important services:

- `CounterpartyVisibilityService`
- `CounterpartyDuplicateService`
- `ServiceAvailabilityService`
- `ContractApplicabilityService`
- `PricingResolver`
- `QuoteCalculator`
- `QuoteWorkflowService`

Do not put pricing resolution logic in controllers.

## 40. Web modules

```text
apps/web/
  app/(protected)/crm/
    counterparties/
    contacts/
    activities/
    services/
    contracts/
    price-books/
    quotes/
```

Reusable components:

- ScopeBadge
- CounterpartyPicker
- ContactPicker
- ServicePicker
- MoneyInput
- EffectiveDateRange
- PriceSourceBadge
- ApprovalTimeline
- VersionBanner
- AuditTimeline

All strings through i18n keys.

---

# PART N — IMPLEMENTATION ORDER

## 41. Phase 03A — Counterparty master

1. Migration and seeds.
2. Permissions.
3. Counterparty visibility policy.
4. Counterparty CRUD.
5. Types/identifiers.
6. contacts/addresses.
7. entity profiles.
8. negative isolation tests.

## 42. Phase 03B — Preferences and activities

1. document preferences
2. billing profiles
3. recipient configuration
4. CRM activity timeline
5. audit

## 43. Phase 03C — Service catalog

1. service CRUD
2. localizations
3. availability
4. scope rules
5. tests

## 44. Phase 03D — Contracts

1. contract aggregate
2. contract versions
3. approval/activation guards
4. contract services
5. immutability tests

## 45. Phase 03E — Pricing

1. price-book CRUD
2. price items
3. deterministic resolver
4. ambiguity/no-price errors
5. resolve-test UI
6. unit/integration tests

## 46. Phase 03F — Quotes

1. quote/revision model
2. quote items
3. server-side calculator
4. approval workflow
5. status guards
6. UI
7. audit/e2e

---

# PART O — ACCEPTANCE CRITERIA

## 47. Functional acceptance

Block 03 is accepted when:

- A scoped Sales user can create and manage a counterparty without exposing it to unrelated branches.
- A counterparty can have multiple types, identifiers, contacts and addresses.
- Legal-entity-specific billing/commercial settings work.
- Document language/recipient preferences are configurable.
- Service names localize without duplicating services.
- Service availability blocks invalid branch/service combinations.
- Contract active terms are versioned and immutable.
- Historical contract versions remain readable.
- Pricing resolution follows the specified hierarchy and returns provenance.
- Ambiguous pricing never silently resolves.
- Quote totals are calculated server-side.
- Quote approval is scope/permission aware.
- Accepted/sent quotes cannot be silently edited.
- A quote preserves price/service/commercial snapshots.
- No cross-branch/cross-entity unauthorized read/write occurs.

## 48. Technical acceptance

- Clean migration succeeds from baseline + Block 02.
- Seed is idempotent.
- OpenAPI fragment validates and is merged into source of truth.
- Unit tests cover pricing/calculation/workflow.
- Integration tests cover scope isolation.
- E2E covers create client → contract → price → quote → accept.
- Optimistic concurrency tests pass.
- Audit records exist for critical changes.
- No float arithmetic for money.
- No client-side authoritative totals.
- No `MAX()+1` numbering.
- lint/typecheck/tests/build all pass.

---

# PART P — OUT OF SCOPE

## 49. Explicitly deferred

Do not implement in Block 03:

- Job creation/conversion
- inspector scheduling
- inspection forms
- sample chain of custody
- laboratory/LIMS
- media evidence
- final report/certificate engine
- invoicing/accounting/general ledger
- payment collection
- client portal account provisioning
- outbound email delivery
- opportunity pipeline/lead scoring
- procurement
- automatic FX trading/conversion

Block 03 only prepares clean contracts/interfaces for those modules.

---

## 50. Definition of Done for Codex

Codex may report Block 03 complete only when:

1. migration + seed succeed on clean DB;
2. all Block 03 permission codes exist;
3. counterparty isolation negative tests pass;
4. active contract versions are immutable;
5. pricing hierarchy and ambiguity tests pass;
6. quote money calculations use decimal/numeric semantics;
7. quote workflow guard tests pass;
8. audit events are persisted for critical mutations;
9. OpenAPI and implementation match;
10. UI is permission/scope aware;
11. all UI strings are localized;
12. lint passes;
13. typecheck passes;
14. tests pass;
15. production build passes;
16. no Block 04+ business domain is accidentally implemented.

The output of Block 03 must leave a stable commercial contract for Block 04:

`counterparty_id + counterparty_entity_profile + contract_id/version_id + accepted quote/revision + selected service(s) + snapshotted price/commercial preferences`.
