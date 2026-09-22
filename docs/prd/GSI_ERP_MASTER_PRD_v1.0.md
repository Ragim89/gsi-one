# GSI ERP MASTER PRD v1.0

**Product:** GSI ONE — Global Inspection Operating Platform  
**Company:** General Survey Inspection (GSI)  
**Document version:** 1.0  
**Prepared:** 2026-09-22  
**Primary implementation target:** OpenAI Codex / AI-assisted engineering  
**Status:** Implementation baseline / requires stakeholder validation of legal, finance and accreditation details

---

## 0. Executive summary

GSI ONE is not a generic ERP. It is a specialized global operating system for inspection, supervision, sampling, laboratory testing, report/certificate issuance, billing and management reporting.

The central business object is a **Job / Inspection Order**, not an invoice or CRM lead. Every operational and financial record should ultimately be traceable to a Job, branch/legal entity, counterparty and responsible employee.

The target end-to-end chain is:

`Client → Contract/Quote → Job → Field Inspection → Evidence → Sample → Laboratory → QC/Approval → Report/Certificate → Invoice → Payment → Profitability → Group Dashboard`

The system must be built for a multi-country company from day one. Countries, legal entities, branches, laboratories, offices, currencies, languages, numbering rules, tax fields, document templates and accreditation scopes are data/configuration — never hard-coded application logic.

The platform is API-first and must support a web back office, an inspector mobile application, a client portal and future integration with existing GSI applications.

---

## 1. Research basis and product assumptions

### 1.1 Publicly verified company characteristics

As of the preparation date, GSI publicly presents itself as an international inspection company focused on agricultural commodities, weight/quantity supervision, sampling, loading/discharge supervision, quality supervision, vessel/hold inspection, fumigation and laboratory services. Public company materials also describe laboratory work such as GMO, chemical/pesticide, microbiology, pesticide residue, mycotoxin and vitamin/mineral testing.

The current GSI website publicly lists operations/offices in Türkiye, Romania, Ukraine, Uzbekistan, Kazakhstan, the United Arab Emirates and Italy. This list must be treated as **seed configuration only**; the ERP must allow countries and branches to be added, deactivated, renamed or reorganized without code changes.

GSI also has a current mobile application named **General Survey Operations**, described as connecting field activities with back-office management, real-time operational oversight, notifications and multimedia capture. Therefore GSI ONE must expose stable APIs that can support either integration with, gradual migration from, or replacement of existing operational tooling.

### 1.2 Product assumptions requiring GSI validation

The following are architecture assumptions, not claims about current internal GSI processes:

- One corporate group contains multiple legal entities and branches.
- A Job may involve more than one GSI branch/legal entity, but one entity is the contracting/billing owner.
- An inspection can generate multiple samples and multiple laboratory requests.
- Laboratory work may be performed by a GSI laboratory or an approved external laboratory.
- Final certificates/reports require configurable review/approval rules.
- Issued documents are immutable; corrections create revisions/superseding documents.
- Finance may initially integrate with an external accounting system instead of replacing statutory accounting in every country.
- “Capitalization” is interpreted as internal **book equity / estimated enterprise value / estimated equity value**, not public-market capitalization.

---

## 2. Product vision

### 2.1 Vision statement

Create a single source of operational and financial truth for GSI worldwide, connecting every inspection event, sample, laboratory result, report, invoice and branch-level financial outcome in one secure, multilingual system.

### 2.2 Product principles

1. **Job-centric** — every operation is organized around an inspection Job.
2. **Global by default** — no country-specific behavior is hard-coded.
3. **Evidence first** — photos, video, measurements, signatures and chain-of-custody are first-class records.
4. **Compliance aware** — accreditation and authorization scopes are validated before document issuance.
5. **Immutable issuance** — issued reports/certificates cannot be silently edited.
6. **Offline capable** — field staff must be able to work with weak or no connectivity.
7. **Audit everything important** — who, what, when, where, previous value and new value.
8. **API first** — web, mobile, client portal and third-party integrations consume the same domain APIs.
9. **Configurable, not custom-coded** — branches, languages, templates, numbering, workflows and service catalogs live in admin data.
10. **Progressive architecture** — begin with a modular monolith; split services only when operational evidence justifies it.

---

## 3. Goals and non-goals

### 3.1 Business goals

- Reduce manual copying between email, spreadsheets, field messaging, laboratory sheets and document templates.
- Provide management with live operational status across all countries.
- Reduce report turnaround time.
- Create traceable chain-of-custody for samples.
- Make photo/video evidence searchable and linked to the exact Job/inspection stage.
- Produce branded, multilingual client reports and certificates.
- Prevent issuance under an invalid or out-of-scope accreditation configuration.
- Provide real-time receivables, revenue, margin, WIP and consolidated financial views.
- Provide a defensible internal valuation dashboard based on configurable valuation models.
- Support expansion to new legal entities and branches with configuration rather than engineering work.

### 3.2 Technical goals

- Typed, documented API.
- Strong authorization with organization and branch scopes.
- Reliable offline synchronization for field operations.
- Direct-to-object-storage media upload.
- Append-only audit trail and issued-document history.
- Automated tests for business-critical workflow transitions.
- Repeatable migrations and seed data.
- Observability: logs, metrics, traces and alerting.

### 3.3 Non-goals for v1

- Full replacement of statutory payroll in every country.
- Full tax engine for all jurisdictions.
- General-purpose warehouse ERP unrelated to GSI operational samples/equipment.
- Public blockchain notarization.
- Fully autonomous AI approval of laboratory results or certificates.
- Automatic legal interpretation of accreditation rules.
- Public-company market capitalization.

---

## 4. Success metrics

Initial targets to be refined after baseline measurement:

- ≥ 95% of active inspection Jobs created and managed in GSI ONE.
- ≥ 90% of field evidence uploaded through the platform.
- ≥ 90% of reports generated from controlled templates.
- 100% of issued reports/certificates have a version, issuer, timestamp and verification record.
- 100% of sample custody movements are timestamped and attributable.
- Median final report turnaround reduced by at least 30% from baseline.
- Financial dashboard freshness: < 5 seconds after posting an internal financial transaction; FX freshness shown explicitly.
- Operational status freshness: < 2 seconds for connected users.
- Mobile offline queue sync success > 99.5% after connectivity returns.
- No cross-branch unauthorized data exposure in automated access-control tests.

---

# PART A — INFORMATION ARCHITECTURE

## 5. Global navigation

### 5.1 Primary menu

1. **Home**
2. **Operations**
3. **Jobs**
4. **Inspections**
5. **Samples**
6. **Laboratory**
7. **Media**
8. **Reports & Certificates**
9. **Clients & Contracts**
10. **Finance**
11. **People**
12. **Assets & Calibration**
13. **Compliance & Quality**
14. **Analytics & Valuation**
15. **Administration**

The menu is permission-aware. Users must not see modules to which they have no read access.

### 5.2 Global top bar

- Organization/legal entity selector
- Branch selector
- Global search
- Quick create (`Job`, `Counterparty`, `Sample`, `Expense` depending on permissions)
- Language selector
- Notifications
- Sync state (mobile/PWA only)
- User profile
- Help / SOP links

### 5.3 Global search

Search by:

- Job number
- Counterparty name/code
- Vessel name / IMO (if captured)
- Truck/wagon/container/seal number
- Sample ID
- Report/certificate number
- Invoice number
- Employee
- Location
- Commodity

Search results must be filtered by authorization scope before display.

---

## 6. Screen inventory

### 6.1 Authentication and identity

| Route | Screen | Key functions |
|---|---|---|
| `/login` | Sign in | OIDC/SSO, dev login only in non-production |
| `/mfa` | MFA | TOTP/WebAuthn depending on IdP |
| `/profile` | My profile | Language, timezone, signature, notification preferences |
| `/sessions` | Active sessions | View/revoke own sessions |

### 6.2 Executive dashboards

| Route | Screen | Key functions |
|---|---|---|
| `/dashboard` | Global dashboard | Group KPIs, jobs, revenue, WIP, AR, cash, alerts |
| `/dashboard/operations` | Operations dashboard | Live jobs, delays, inspectors, countries, activity feed |
| `/dashboard/lab` | Laboratory dashboard | Samples, turnaround time, queues, out-of-spec alerts |
| `/dashboard/finance` | Finance dashboard | Revenue, AR/AP, cash, margin, branch P&L |
| `/dashboard/compliance` | Compliance dashboard | Accreditation expiry, calibration expiry, approvals |
| `/dashboard/valuation` | Valuation dashboard | Book equity, EV/equity models, scenarios, history |

### 6.3 Organization management

| Route | Screen | Key functions |
|---|---|---|
| `/org/group` | Group profile | Group name, reporting currency, fiscal settings |
| `/org/legal-entities` | Legal entities | Country, registration/tax fields, base currency |
| `/org/branches` | Branches | Branch configuration, contacts, numbering, templates |
| `/org/locations` | Locations | Offices, ports, warehouses, labs, client sites |
| `/org/labs` | Laboratories | Internal/external lab configuration |
| `/org/bank-accounts` | Bank accounts | Entity-owned accounts, currencies, IBAN/local fields |
| `/org/localization` | Localization profiles | Languages, timezone, formats, tax labels, fiscal year |
| `/org/sequences` | Number sequences | Job/report/invoice/sample numbering rules |

### 6.4 CRM, clients and contracts

| Route | Screen | Key functions |
|---|---|---|
| `/crm/counterparties` | Counterparty list | Client/vendor/lab/agent/subcontractor filtering |
| `/crm/counterparties/:id` | Counterparty profile | Contacts, contracts, jobs, documents, billing prefs |
| `/crm/contacts` | Contacts | Contact directory |
| `/crm/opportunities` | Opportunities | Optional sales pipeline |
| `/crm/quotes` | Quotes | Quote creation, pricing, approval, conversion to Job |
| `/crm/contracts` | Contracts | Contract terms, effective dates, files, price linkage |
| `/crm/price-books` | Price books | Country/client/service-specific pricing |

### 6.5 Jobs and operations

| Route | Screen | Key functions |
|---|---|---|
| `/jobs` | Job list | Advanced filters, saved views, export |
| `/jobs/board` | Job board | Kanban by operational stage |
| `/jobs/calendar` | Job calendar | Schedule by branch/inspector |
| `/jobs/map` | Job map | Active geographic operations where coordinates exist |
| `/jobs/new` | Create Job wizard | Client, service, cargo, scope, location, schedule |
| `/jobs/:id` | Job workspace | Full tabbed operational record |
| `/jobs/:id/overview` | Overview | Summary, status, owner, SLA, warnings |
| `/jobs/:id/scope` | Scope | Services, standards, instructions, deliverables |
| `/jobs/:id/parties` | Parties | Buyer/seller/shipper/receiver/agent/etc. |
| `/jobs/:id/cargo` | Cargo | Commodity, quantity, package, lot, origin/destination |
| `/jobs/:id/transport` | Transport | Vessel/truck/wagon/container details |
| `/jobs/:id/schedule` | Schedule | Milestones, shifts, ETA/ETD, deadlines |
| `/jobs/:id/team` | Team | Inspectors, reviewers, labs, subcontractors |
| `/jobs/:id/inspections` | Inspections | Inspection runs and forms |
| `/jobs/:id/samples` | Samples | Sample tree and chain-of-custody |
| `/jobs/:id/lab` | Laboratory | Test requests/results |
| `/jobs/:id/media` | Evidence | Photo/video/document gallery |
| `/jobs/:id/reports` | Reports | Drafts, approvals, issued docs |
| `/jobs/:id/expenses` | Costs | Travel, subcontractor, lab, per diem, misc. |
| `/jobs/:id/billing` | Billing | Quote, invoice lines, invoice/payment status |
| `/jobs/:id/timeline` | Timeline | Chronological event stream |
| `/jobs/:id/audit` | Audit | Job-scoped audit history |

### 6.6 Field inspection screens

| Route | Screen | Key functions |
|---|---|---|
| `/field/today` | My day | Assigned Jobs and tasks |
| `/field/jobs/:id` | Field Job | Offline-ready job summary |
| `/field/jobs/:id/start` | Start inspection | Start time, location, safety confirmation |
| `/field/inspections/:id/form` | Inspection form | Dynamic checklist/form, measurements |
| `/field/inspections/:id/media` | Capture evidence | Photo/video, categories, notes |
| `/field/inspections/:id/samples` | Create sample | ID/QR, seal, quantity, matrix, location |
| `/field/inspections/:id/complete` | Complete | Required checks, signature, handoff |
| `/field/sync` | Sync center | Pending uploads/actions/conflicts |

### 6.7 Samples and chain-of-custody

| Route | Screen | Key functions |
|---|---|---|
| `/samples` | Sample registry | Filters by status, lab, Job, date |
| `/samples/:id` | Sample profile | Metadata, seals, splits, tests, custody |
| `/samples/:id/custody` | Custody timeline | Every transfer and responsible person |
| `/samples/:id/label` | Label | QR/barcode and printable label |
| `/samples/receive` | Receive samples | Batch scan at lab |
| `/samples/disposal` | Disposal queue | Retention deadline and approval |

### 6.8 Laboratory / LIMS

| Route | Screen | Key functions |
|---|---|---|
| `/lab` | LIMS dashboard | Queue, TAT, overdue, OOS |
| `/lab/requests` | Test requests | Accession and assignment |
| `/lab/requests/:id` | Test request | Methods, parameters, sample, result state |
| `/lab/worklist` | Analyst worklist | Tests assigned to analyst/instrument |
| `/lab/results/:id` | Result entry | Value, unit, LOD/LOQ, flags, attachments |
| `/lab/qc` | QC review | Technical review and approval |
| `/lab/methods` | Test methods | Version-controlled methods |
| `/lab/parameters` | Parameters | Units, precision, default rules |
| `/lab/specifications` | Specifications | Client/commodity/regulatory limits |
| `/lab/instruments` | Instruments | Status, calibration, maintenance |

### 6.9 Media and evidence

| Route | Screen | Key functions |
|---|---|---|
| `/media` | Global media library | Authorized search/filter only |
| `/media/:id` | Media detail | Original, preview, metadata, hash, links |
| `/media/uploads` | Upload monitor | Multipart uploads, failed uploads, transcode state |

### 6.10 Reports and certificates

| Route | Screen | Key functions |
|---|---|---|
| `/documents/templates` | Template library | Branch/service/language templates |
| `/documents/templates/:id` | Template studio | Header/footer/body blocks, variables |
| `/reports` | Report queue | Draft/review/approval/issued |
| `/reports/:id` | Report editor | Controlled data + narrative fields |
| `/reports/:id/preview` | Preview | PDF preview for selected language/template |
| `/reports/:id/review` | Review | Findings, comments, approval actions |
| `/certificates` | Certificate registry | Issued/superseded/revoked status |
| `/verify/:token` | Public verification | Minimal certificate validity page |

### 6.11 Finance

| Route | Screen | Key functions |
|---|---|---|
| `/finance/overview` | Finance overview | Revenue, margin, AR/AP, cash |
| `/finance/invoices` | Invoices | Draft/post/send/credit/reconciliation |
| `/finance/invoices/:id` | Invoice detail | Lines, taxes, documents, allocations |
| `/finance/payments` | Payments | Incoming/outgoing payment ledger |
| `/finance/expenses` | Expenses | Job-linked costs and approvals |
| `/finance/receivables` | AR aging | Aging by client/entity/branch |
| `/finance/payables` | AP aging | Aging by vendor |
| `/finance/journals` | Management ledger | Optional internal GL postings |
| `/finance/fx` | FX rates | Provider/manual, date, source, stale flag |
| `/finance/budgets` | Budgets | Branch/entity budgets |

### 6.12 People

| Route | Screen | Key functions |
|---|---|---|
| `/people/employees` | Employees | Employment, branch, role, skills |
| `/people/employees/:id` | Employee | Qualifications, availability, documents |
| `/people/schedule` | Resource schedule | Assignments and leave/availability |
| `/people/timesheets` | Timesheets | Job hours, travel hours |
| `/people/qualifications` | Qualifications | Expiry, scope, evidence |

### 6.13 Assets and calibration

| Route | Screen | Key functions |
|---|---|---|
| `/assets/equipment` | Equipment | Serial, owner, location, status |
| `/assets/equipment/:id` | Equipment profile | Calibration and maintenance history |
| `/assets/calibrations` | Calibration queue | Due/expired/blocked equipment |
| `/assets/maintenance` | Maintenance | Service history and downtime |

### 6.14 Compliance and quality

| Route | Screen | Key functions |
|---|---|---|
| `/compliance/accreditations` | Accreditation registry | Entity, scope, dates, status |
| `/compliance/scopes` | Scope matrix | Service/commodity/method mapping |
| `/compliance/document-control` | Controlled documents | SOPs, revisions, approvals |
| `/compliance/incidents` | Incidents/NCR | Nonconformity records |
| `/compliance/capa` | CAPA | Corrective/preventive actions |
| `/compliance/approvals` | Approval queue | Reports, changes, exceptions |

### 6.15 Analytics and valuation

| Route | Screen | Key functions |
|---|---|---|
| `/analytics/operations` | Operational BI | Volumes, TAT, job performance |
| `/analytics/clients` | Client BI | Revenue, jobs, margin, receivables |
| `/analytics/branches` | Branch BI | Revenue/cost/margin/headcount |
| `/analytics/services` | Service BI | Volume/margin/TAT by service |
| `/analytics/valuation` | Valuation | Book equity, EV, equity, scenarios |
| `/analytics/valuation/settings` | Valuation assumptions | Multiples, WACC, growth, net debt rules |

### 6.16 Administration

| Route | Screen | Key functions |
|---|---|---|
| `/admin/users` | Users | Identity linkage, status, scopes |
| `/admin/roles` | Roles | RBAC templates |
| `/admin/permissions` | Permission matrix | Fine-grained actions |
| `/admin/workflows` | Workflow configuration | Allowed transitions/approvers |
| `/admin/dictionaries` | Master data | Commodities, units, services, statuses |
| `/admin/languages` | Languages | Enabled locale configuration |
| `/admin/translations` | Content translations | Master-data labels and templates |
| `/admin/integrations` | Integrations | Email, accounting, FX, IdP, storage |
| `/admin/api-keys` | API clients | Service accounts and scopes |
| `/admin/webhooks` | Webhooks | Subscriptions and delivery logs |
| `/admin/audit` | Audit log | Global append-only audit viewer |
| `/admin/imports` | Imports | Migration/import jobs and reconciliation |

---

# PART B — USERS, ROLES AND AUTHORIZATION

## 7. Role model

Roles are templates. Actual access = **role permissions + organization scope + record assignment + contextual policies**.

### 7.1 Standard roles

1. **Group Super Admin** — platform administration; not automatically allowed to approve compliance documents.
2. **Group CEO / Board Viewer** — group-wide executive read access.
3. **Group CFO** — group-wide finance and valuation.
4. **Group COO** — group-wide operations.
5. **Group Quality/Compliance Director** — accreditations, controlled docs, final compliance approvals.
6. **Country Director** — all authorized entities/branches in a country.
7. **Branch Manager** — branch operations, local personnel, limited finance.
8. **Operations Manager / Dispatcher** — Jobs, scheduling, assignments.
9. **Senior Inspector / Reviewer** — field operations plus technical review where authorized.
10. **Inspector** — assigned Jobs/inspections only, limited client/finance visibility.
11. **Sample Custodian** — sample receipt, transfer, storage, disposal.
12. **Lab Director** — laboratory administration and final technical approval.
13. **Lab Analyst** — assigned tests/results.
14. **Finance Manager** — entity/branch finance.
15. **Accountant** — invoices, payments, journals according to scope.
16. **Sales/CRM** — counterparties, quotes, contracts, limited Jobs.
17. **HR/People Admin** — employee data and qualifications.
18. **Equipment/Calibration Manager** — asset and calibration records.
19. **Compliance Auditor (Read Only)** — controlled read access and audit exports.
20. **Client User** — only their counterparty’s authorized Jobs/documents/invoices.
21. **Integration Service Account** — API-only, explicit scopes, no interactive login.

### 7.2 Permission naming convention

`<domain>.<resource>.<action>`

Examples:

- `jobs.job.read`
- `jobs.job.create`
- `jobs.job.assign`
- `inspection.form.complete`
- `samples.custody.transfer`
- `lab.result.enter`
- `lab.result.approve`
- `reports.report.approve`
- `reports.certificate.issue`
- `finance.invoice.post`
- `finance.payment.reconcile`
- `compliance.accreditation.manage`
- `admin.user.manage`

### 7.3 Authorization scopes

Each user role assignment may carry:

- `group`
- `country`
- `legal_entity`
- `branch`
- `laboratory`
- `job_assignment_only`
- `counterparty_only` (client users)

### 7.4 Separation of duties

Configurable policies must support rules such as:

- Analyst cannot perform final approval of their own test result unless explicitly permitted.
- Report author cannot be sole final approver for selected document classes.
- Inspector cannot alter an issued report.
- Finance creator and approver can be separated for high-value invoices/payments.
- Accreditation administrator cannot retroactively backdate a scope without elevated approval and audit reason.

---

# PART C — ORGANIZATION, LOCALIZATION AND MULTI-CURRENCY

## 8. Organization hierarchy

Recommended hierarchy:

`GSI Group → Legal Entity → Branch → Operational Location / Laboratory / Office`

A Job has:

- `owner_legal_entity_id` — contracting/billing owner.
- `owner_branch_id` — operating owner.
- optional supporting branches/entities via assignments.

### 8.1 Legal entity configuration

- Legal name
- Trading name
- Registration number
- Tax identifiers (typed key/value to support country differences)
- Country
- Registered address
- Base currency
- Fiscal year start
- Default language(s)
- Timezone
- Bank accounts
- Document footer data
- Signature policy
- Tax/invoice configuration
- Active/inactive dates

### 8.2 Branch configuration

- Code
- Name
- Legal entity
- Country/city
- Timezone override
- Operational email/phone
- Default report template family
- Job/report/sample/invoice numbering sequences
- Default laboratory
- Cost center
- Allowed service catalog
- Allowed document languages
- Data-storage region policy (configuration only; legal validation required)

## 9. Localization

### 9.1 Initial target locales

The system must support any BCP-47 locale. Seed configuration should include:

- `en`
- `tr`
- `ru`
- `kk`
- `uk`
- `ro`
- `uz`
- `it`
- `ar`

Do not assume every branch enables all languages.

### 9.2 Localization layers

1. **UI translations** — version-controlled i18n message files.
2. **Master-data translations** — database-managed localized labels for services, commodities, units, methods, statuses.
3. **Document translations** — template-specific language variants.
4. **Client preferences** — preferred language(s) and document naming rules.
5. **Locale formats** — date/time/number/currency rendering.

### 9.3 Content rules

- Canonical codes are language-neutral.
- Translated text must never be used as a database key.
- Measurements store numeric value + canonical unit; translation affects display label only.
- User-entered narrative text retains original language; optional translated versions are separate records and never overwrite original text.

## 10. Multi-currency

Every monetary record stores:

- transaction currency
- transaction amount
- FX rate used for reporting
- FX rate date/time/source
- group reporting currency amount
- entity reporting currency amount where needed

No historical financial amount should silently change when new FX rates arrive. Revaluation is a separate explicit process.

---

# PART D — CORE BUSINESS WORKFLOWS

## 11. Job workflow

### 11.1 Job status model

Recommended primary states:

`DRAFT → CONFIRMED → SCHEDULED → IN_PROGRESS → FIELD_COMPLETE → LAB_PENDING/LAB_IN_PROGRESS → REPORT_DRAFT → REVIEW → APPROVED → ISSUED → INVOICED → CLOSED`

Side states:

- `ON_HOLD`
- `CANCELLED`

A Job may skip laboratory states when no laboratory work is required. Do not encode the workflow as one rigid sequence; use services/tasks and guarded transitions.

### 11.2 Job creation wizard

Step 1 — Ownership
- legal entity
- branch
- job type
- responsible operations manager

Step 2 — Client/contract
- counterparty
- contract
- quote
- purchase order/reference
- billing contact

Step 3 — Scope
- service(s)
- standard/method/reference
- deliverables
- requested document language(s)
- special client instructions

Step 4 — Cargo
- commodity
- quantity and unit
- lot/batch
- packaging
- origin/destination

Step 5 — Transport/location
- vessel / truck / wagon / container / warehouse / port
- operational location(s)
- ETA/ETD or planned start/end

Step 6 — Team
- inspector(s)
- reviewer
- laboratory
- subcontractor(s)

Step 7 — Commercial
- pricing
- estimate
- currency
- invoice rules

Step 8 — Validation
- missing contract fields
- accreditation scope warnings
- qualification warnings
- scheduling conflicts

### 11.3 Job transition guards

Examples:

- Cannot move to `SCHEDULED` without required operational location and planned date.
- Cannot start an inspection if assigned inspector is inactive.
- Can warn or block if required qualification is expired based on service policy.
- Cannot issue final report without configured approval completion.
- Cannot close Job while mandatory invoices/documents remain incomplete unless an authorized override with reason is recorded.

---

## 12. Inspection workflow

`PLANNED → ASSIGNED → READY → STARTED → PAUSED (optional) → FIELD_COMPLETE → REVIEW_REQUIRED (optional) → ACCEPTED`

`CANCELLED` is available with mandatory reason.

### 12.1 Inspection form architecture

Inspection forms are versioned schemas. A Job references the exact form version used. Forms support:

- text
- number
- decimal
- date/time
- boolean
- single/multi select
- measurement value + unit
- photo required
- video required
- signature
- GPS capture (only when permitted)
- barcode/QR scan
- repeated groups, e.g. multiple wagon rows
- conditional visibility
- required-field rules
- validation limits
- computed fields

Never mutate a published form version. Create a new version.

### 12.2 Mobile field completion

1. Inspector downloads assigned Job package.
2. App stores required Job data locally.
3. Inspector starts inspection; local timestamp is captured.
4. Dynamic form/checklists are completed offline if necessary.
5. Photo/video evidence is queued with checksum and metadata.
6. Samples can be created with temporary offline IDs mapped to server IDs at sync.
7. Inspector signs/completes inspection.
8. Sync queue uploads structured actions first, large media second.
9. Server validates and returns acknowledgements/conflicts.
10. Operations manager/reviewer sees real-time completion when connected.

### 12.3 Offline conflict rules

- Attachments/events are append-only: no merge conflict.
- Inspection forms are locked to the assigned inspector while actively edited, with administrative takeover capability.
- Server-authoritative fields: assignment, legal entity, client, status transitions, accreditation decision.
- User draft narrative may use optimistic versioning; conflicts require explicit resolution.
- Never silently discard offline changes.

---

## 13. Media evidence workflow

### 13.1 Upload pipeline

`CREATE UPLOAD → PRESIGNED MULTIPART → CLIENT UPLOAD → COMPLETE → CHECKSUM VERIFY → MALWARE SCAN → METADATA EXTRACT → PREVIEW/TRANSCODE → AVAILABLE`

### 13.2 Required metadata

- uploader
- captured_at (device time)
- server_received_at
- Job/inspection linkage
- category
- original filename
- MIME type
- file size
- SHA-256
- optional location coordinates if captured with permission
- device/application metadata where available
- original object key
- derivative/preview keys

### 13.3 Evidence integrity

- Originals are immutable.
- Cropped/compressed/annotated files are derivatives linked to the original.
- Generated report images reference a specific derivative version.
- Deletion uses retention and authorization policy; evidence linked to an issued document cannot be physically deleted through normal UI.

---

## 14. Sampling and chain-of-custody workflow

`CREATED → COLLECTED → SEALED → IN_TRANSIT → RECEIVED → ACCESSIONED → SPLIT (optional) → TESTING → RETAINED → DISPOSAL_DUE → DISPOSED`

### 14.1 Sample identity

Human-readable sample number generated by configurable sequence, e.g.:

`GSI-KZ-2026-001872`

Database identity remains UUID.

### 14.2 Custody movement

Every custody event stores:

- sample
- from custodian/location
- to custodian/location
- event type
- timestamp
- user
- seal state/number
- condition notes
- optional signature/photo
- immutable audit reference

### 14.3 Sample split

A parent sample may produce one or more child splits. The relationship must remain visible for the lifetime of the records.

---

## 15. Laboratory workflow

`REQUESTED → SAMPLE_RECEIVED → ACCESSIONED → ASSIGNED → IN_TESTING → RESULT_ENTERED → TECHNICAL_REVIEW → APPROVED → REPORTED`

Side states:

- `ON_HOLD`
- `RETEST_REQUIRED`
- `CANCELLED`
- `OUTSOURCED`

### 15.1 Test request structure

A test request contains:

- sample
- requesting Job
- laboratory
- requested tests/parameters
- method/version
- specification/limits
- priority
- due date
- client instructions
- accreditation requirement

### 15.2 Result model

A result supports:

- numeric result
- text/qualitative result
- unit
- uncertainty where applicable
- LOD/LOQ where applicable
- pass/fail/OOS evaluation
- analyst
- instrument
- method version
- performed timestamp
- attachments/raw files reference
- review and approval records

Do not hard-code universal PASS/FAIL thresholds. Evaluation must reference the selected specification version or explicit client contract rule.

### 15.3 Laboratory QC

Configurable review may check:

- method validity on test date
- instrument calibration status
- analyst qualification
- required controls/blanks where modeled
- result precision/range rules
- specification evaluation
- accreditation scope

Critical QC warnings can block approval; override requires permission + reason and is auditable.

---

## 16. Report and certificate workflow

`DRAFT → AUTHOR_REVIEW → TECHNICAL_REVIEW → COMPLIANCE_REVIEW (if required) → APPROVED → ISSUED`

Post-issue states:

- `SUPERSEDED`
- `REVOKED` (only when business/legal policy permits; reason mandatory)

### 16.1 Document generation

A report is generated from:

- template version
- legal entity/branch branding
- Job data
- client profile
- inspection data
- selected media
- sample/test results
- accreditation/qualification data
- signatures
- language selection

### 16.2 Template resolution order

Recommended matching priority:

1. Counterparty + branch + service + language
2. Counterparty + legal entity + service + language
3. Branch + service + language
4. Legal entity + service + language
5. Group default + service + language
6. Group generic default

Template resolution must be deterministic and visible in preview metadata.

### 16.3 Issuance controls

Before issue:

- required reviewers approved
- relevant test results approved
- document numbering reserved
- legal entity details valid for issue date
- accreditation rule evaluated
- required signatures present
- no blocking compliance warning

### 16.4 Immutability and revisions

On issue:

- render PDF
- calculate SHA-256
- persist exact template version + data snapshot used
- assign public verification token
- store issuer/time
- lock version

Correction creates a new document revision referencing the prior revision. The old revision remains accessible to authorized users and marked superseded.

---

# PART E — CLIENT PORTAL

## 17. Client portal scope

Client users are linked to a counterparty and optionally restricted further by division/project.

### 17.1 Client screens

- Dashboard
- Active Jobs
- Job timeline
- Reports/certificates
- Laboratory results authorized for release
- Media authorized for release
- Invoices and payment status
- Contacts/support

### 17.2 Client access rules

Client portal must not expose:

- internal margins
- internal notes
- unrelated counterparties
- internal compliance discussions
- staff HR data
- unreleased draft results unless explicitly configured

### 17.3 Secure sharing

Documents can additionally be shared by expiring signed link when permitted. Public certificate verification displays only minimal verification data and never exposes internal Job detail.

---

# PART F — FINANCE AND REAL-TIME VALUE

## 18. Finance model

The first implementation should support management finance directly and allow statutory accounting integration per country.

Core entities:

- quotes
- invoice drafts
- posted invoices
- credit notes
- payments
- payment allocations
- expenses
- subcontractor costs
- laboratory costs
- internal time costs (optional)
- management journals
- FX rates

### 18.1 Job profitability

For each Job calculate:

`Revenue - direct labor - travel - external lab - subcontractor - consumables - other direct costs = Contribution Margin`

Optional allocations add branch overhead for fully-loaded profitability.

### 18.2 Posting rules

- Draft documents may change.
- Posted financial documents require reversal/credit workflows, not silent edits.
- Every invoice line should link to Job/service when possible.
- Payment allocation maintains audit history.

## 19. “Capitalization” / value dashboard

Because GSI is a private company, the platform should present **management valuation**, not public-market capitalization.

### 19.1 Live value metrics

- Cash
- Accounts receivable
- Accounts payable
- Net working capital
- Book assets
- Book liabilities
- Book equity / net assets
- Revenue YTD / LTM
- EBITDA YTD / LTM (management definition)
- Net debt
- WIP
- Backlog

### 19.2 Valuation models

1. **Book Equity**  
   `Assets - Liabilities`

2. **EBITDA Multiple / Enterprise Value**  
   `LTM EBITDA × configured multiple`

3. **Estimated Equity Value**  
   `Enterprise Value - Net Debt ± configured adjustments`

4. **DCF**  
   Configurable forecast period, FCF assumptions, WACC and terminal growth.

All assumptions are user-configured and versioned. The dashboard must display the model name, assumptions date and last recalculation time.

### 19.3 Real-time architecture for management KPIs

- Domain transaction commits write to `outbox_events` in the same DB transaction.
- Worker consumes events and updates aggregate read models/materialized tables.
- Connected dashboards receive update events via SSE/WebSocket.
- Target operational refresh < 2 seconds.
- Target finance aggregate refresh < 5 seconds after posting.
- FX-sourced values display rate timestamp/source and stale indicator.
- Valuation recalculates on material financial events and scheduled refresh.

---

# PART G — COMPLIANCE, ACCREDITATION AND QUALITY

## 20. Accreditation registry

Store accreditation/certification/membership as versioned records:

- legal entity
- accreditation body
- accreditation number
- type/standard
- effective date
- expiry date
- status
- source document
- notes

### 20.1 Accreditation scope

Scopes may restrict by:

- service
- commodity/category
- test method
- parameter
- location/laboratory
- country
- document type

### 20.2 Compliance engine

At workflow checkpoints, evaluate:

`entity + branch/lab + service/method + commodity + issue/test date + accreditation scope + employee qualification + equipment state`

Result:

- `PASS`
- `WARNING`
- `BLOCK`
- `NOT_APPLICABLE`

Rules are explicit and auditable. The engine does not make legal judgments beyond configured rules.

## 21. Controlled documents

SOPs, methods and controlled forms support:

- owner
- version
- effective date
- superseded date
- approval workflow
- acknowledgment/training requirement
- attachment hash

---

# PART H — DESIGN SYSTEM

## 22. Brand direction

The UI should follow GSI’s recognizable blue/white corporate direction while remaining a dense, professional operational system.

**Important:** the following colors are provisional design tokens until GSI supplies an official SVG/AI/EPS logo and brandbook.

### 22.1 Provisional tokens

- `--gsi-navy: #163D6B`
- `--gsi-blue: #2B66A2`
- `--gsi-light-blue: #73A8D1`
- `--gsi-bg: #F5F7FA`
- `--gsi-surface: #FFFFFF`
- `--gsi-text: #17212B`
- `--gsi-wheat-accent: #D8A24A`

Do not use the wheat accent as a primary UI color. Reserve it for small visual accents and commodity context.

### 22.2 Semantic colors

Semantic status colors must be separate tokens and meet WCAG contrast requirements. Do not rely on color alone: use icon + label + color.

### 22.3 Layout

- Light content canvas
- Dark/navy left navigation
- Dense tables with configurable column visibility
- Sticky filter/action bars
- Responsive desktop-first backoffice
- Touch-first field screens
- Document previews use true paper ratios
- Photo evidence is prominent in Job and inspection views

### 22.4 Accessibility

- WCAG 2.2 AA target
- Keyboard navigation for backoffice
- Visible focus states
- Screen-reader labels
- 44px minimum touch target for mobile actions
- RTL capability for Arabic at layout level

---

# PART I — TECHNICAL ARCHITECTURE

## 23. Recommended stack

### 23.1 Repository

- `pnpm` workspaces
- Turborepo
- TypeScript strict mode

### 23.2 Applications

```text
gsi-one/
  apps/
    web/            # Next.js backoffice
    client/         # Next.js client portal (can initially share web packages)
    mobile/         # Expo React Native inspector app
    api/            # NestJS REST API
    worker/         # BullMQ background workers
  packages/
    ui/
    config/
    auth/
    db/
    domain/
    i18n/
    documents/
    storage/
    observability/
    api-client/
    validation/
```

### 23.3 Core technology

- Frontend: Next.js + React + TypeScript
- Mobile: Expo React Native + local SQLite/offline queue
- API: NestJS + TypeScript
- Database: PostgreSQL
- ORM: Prisma for application model, with raw SQL migrations for advanced PostgreSQL features as needed
- Cache/queues: Redis + BullMQ
- Object storage: S3-compatible object storage
- PDF: server-side HTML/CSS rendered with Chromium/Playwright
- Realtime: SSE for dashboards/notifications; WebSocket only where bidirectional realtime is required
- Auth: OIDC/OAuth2 compatible identity provider; no custom production password cryptography
- Observability: OpenTelemetry + structured logs + metrics + traces

## 24. Architecture style

Use a **modular monolith** for API/domain logic at v1.

Domain modules:

- identity
- organization
- localization
- crm
- jobs
- inspections
- media
- samples
- laboratory
- documents
- compliance
- finance
- people
- assets
- analytics
- notifications
- integrations
- audit

Modules communicate through explicit application services and domain events. Avoid direct cross-module table manipulation from unrelated modules.

## 25. Event/outbox model

Use transactional outbox, not full event sourcing.

Examples:

- `job.created`
- `job.status_changed`
- `inspection.completed`
- `sample.received`
- `lab.result.approved`
- `report.issued`
- `invoice.posted`
- `payment.allocated`
- `accreditation.expiring`

Outbox consumer responsibilities:

- notifications
- dashboard aggregates
- webhooks
- search indexing
- document rendering tasks
- video transcoding tasks

---

# PART J — DATA MODEL AND POSTGRESQL CONTRACT

## 26. Database conventions

- UUID primary keys (`gen_random_uuid()`).
- `timestamptz` for timestamps.
- Money stored as `numeric(20,6)` + currency code; never floating point.
- Measurements stored as `numeric` + canonical unit.
- All mutable business tables include `version integer` for optimistic concurrency.
- `created_at`, `created_by`, `updated_at`, `updated_by` on material business records.
- Soft delete only where legally/business appropriate; never soft-delete audit events or issued document versions.
- Human-readable numbers are unique within configured sequence scope, but are not primary keys.
- JSONB is allowed for extensible metadata and country-specific fields, not as a substitute for core relational modeling.

## 27. Schema modules and core tables

The accompanying `schema.sql` is the implementation seed. Major tables:

### Organization and localization

- `organizations`
- `legal_entities`
- `branches`
- `locations`
- `laboratories`
- `localization_profiles`
- `languages`
- `currencies`
- `exchange_rates`
- `number_sequences`
- `localized_content`

### Identity and authorization

- `users`
- `employees`
- `roles`
- `permissions`
- `role_permissions`
- `user_role_assignments`
- `user_scopes`

### CRM/commercial

- `counterparties`
- `counterparty_contacts`
- `counterparty_addresses`
- `contracts`
- `service_catalog`
- `price_books`
- `price_book_items`
- `quotes`
- `quote_items`

### Jobs/operations

- `jobs`
- `job_services`
- `job_parties`
- `job_cargoes`
- `job_transport_units`
- `job_locations`
- `job_assignments`
- `job_tasks`
- `job_events`

### Inspections

- `inspection_form_definitions`
- `inspection_form_versions`
- `inspections`
- `inspection_responses`

### Media

- `media_files`
- `media_links`
- `upload_sessions`

### Sampling

- `samples`
- `sample_seals`
- `sample_movements`
- `sample_relationships`

### Laboratory

- `test_methods`
- `test_parameters`
- `test_specifications`
- `specification_limits`
- `test_requests`
- `test_request_items`
- `test_results`
- `result_reviews`
- `lab_instruments`
- `calibration_events`

### Reports/documents

- `document_templates`
- `document_template_versions`
- `reports`
- `document_versions`
- `document_approvals`
- `document_signatures`
- `document_verification_tokens`

### Compliance/quality

- `accreditations`
- `accreditation_scopes`
- `employee_qualifications`
- `controlled_documents`
- `quality_incidents`
- `capa_actions`

### Finance

- `bank_accounts`
- `invoices`
- `invoice_lines`
- `payments`
- `payment_allocations`
- `expenses`
- `management_journals`
- `management_journal_lines`
- `valuation_models`
- `valuation_assumptions`
- `valuation_snapshots`

### Platform

- `notifications`
- `comments`
- `outbox_events`
- `webhook_subscriptions`
- `webhook_deliveries`
- `audit_log`
- `import_jobs`

---

# PART K — API CONTRACT

## 28. API conventions

Base path:

`/api/v1`

### 28.1 General rules

- JSON UTF-8
- ISO 8601 timestamps with timezone
- UUID resource IDs
- `Accept-Language` supported for localized labels
- Cursor pagination for high-volume lists
- Stable filtering/sorting syntax
- `Idempotency-Key` required for selected create/post/issue endpoints
- `ETag` / `If-Match` or explicit `version` for optimistic concurrency
- `X-Request-Id` propagated end-to-end
- RFC 7807-style problem responses

### 28.2 Standard list response

```json
{
  "data": [],
  "page": {
    "nextCursor": null,
    "hasMore": false
  },
  "meta": {
    "requestId": "..."
  }
}
```

### 28.3 Standard error

```json
{
  "type": "https://gsi.internal/problems/validation",
  "title": "Validation failed",
  "status": 422,
  "code": "VALIDATION_ERROR",
  "detail": "One or more fields are invalid.",
  "errors": [
    { "field": "plannedStart", "code": "REQUIRED" }
  ],
  "requestId": "..."
}
```

## 29. Core endpoint groups

### Identity

- `GET /me`
- `GET /me/permissions`
- `GET /me/notifications`

### Organization

- `GET/POST /legal-entities`
- `GET/PATCH /legal-entities/{id}`
- `GET/POST /branches`
- `GET/PATCH /branches/{id}`
- `GET/POST /locations`
- `GET/POST /laboratories`
- `GET/POST /localization-profiles`

### Counterparties/commercial

- `GET/POST /counterparties`
- `GET/PATCH /counterparties/{id}`
- `GET/POST /contracts`
- `GET/POST /quotes`
- `POST /quotes/{id}/approve`
- `POST /quotes/{id}/convert-to-job`

### Jobs

- `GET/POST /jobs`
- `GET/PATCH /jobs/{id}`
- `POST /jobs/{id}/transition`
- `GET/POST /jobs/{id}/services`
- `GET/POST /jobs/{id}/assignments`
- `GET/POST /jobs/{id}/tasks`
- `GET /jobs/{id}/timeline`
- `GET /jobs/{id}/profitability`

### Inspections

- `GET/POST /inspection-forms`
- `POST /inspection-forms/{id}/versions`
- `GET/POST /inspections`
- `POST /inspections/{id}/start`
- `PUT /inspections/{id}/responses`
- `POST /inspections/{id}/complete`
- `POST /inspections/{id}/accept`

### Media

- `POST /uploads`
- `POST /uploads/{id}/parts`
- `POST /uploads/{id}/complete`
- `GET /media/{id}`
- `POST /media/{id}/links`

### Samples

- `GET/POST /samples`
- `GET /samples/{id}`
- `POST /samples/{id}/seal`
- `POST /samples/{id}/movements`
- `POST /samples/{id}/split`
- `POST /samples/{id}/dispose`

### Laboratory

- `GET/POST /lab/test-requests`
- `GET/PATCH /lab/test-requests/{id}`
- `POST /lab/test-requests/{id}/assign`
- `POST /lab/results`
- `PATCH /lab/results/{id}`
- `POST /lab/results/{id}/review`
- `POST /lab/results/{id}/approve`

### Reports/documents

- `GET/POST /document-templates`
- `POST /document-templates/{id}/versions`
- `GET/POST /reports`
- `POST /reports/{id}/render-preview`
- `POST /reports/{id}/submit-review`
- `POST /reports/{id}/approve`
- `POST /reports/{id}/issue`
- `POST /reports/{id}/revise`
- `GET /verification/{token}`

### Finance

- `GET/POST /invoices`
- `POST /invoices/{id}/post`
- `POST /invoices/{id}/send`
- `POST /invoices/{id}/credit`
- `GET/POST /payments`
- `POST /payments/{id}/allocations`
- `GET/POST /expenses`
- `GET /finance/ar-aging`
- `GET /finance/job-profitability`

### Analytics and valuation

- `GET /analytics/executive`
- `GET /analytics/operations`
- `GET /analytics/finance`
- `GET /valuation/current`
- `GET /valuation/history`
- `GET/POST /valuation/models`
- `POST /valuation/recalculate`

### Admin/audit/integration

- `GET /audit`
- `GET/POST /webhooks`
- `GET /webhooks/{id}/deliveries`
- `POST /imports`
- `GET /imports/{id}`

### Offline sync

- `POST /sync/push`
- `GET /sync/pull?cursor=...`

The accompanying `openapi.yaml` provides an implementable starter contract.

---

# PART L — OFFLINE SYNC CONTRACT

## 30. Sync push

Client sends an ordered action batch:

```json
{
  "deviceId": "uuid",
  "baseCursor": "opaque-cursor",
  "actions": [
    {
      "clientActionId": "uuid",
      "type": "inspection.response.upsert",
      "entityId": "uuid-or-temp-id",
      "baseVersion": 3,
      "occurredAt": "2026-09-22T10:00:00+05:00",
      "payload": {}
    }
  ]
}
```

Server returns per-action status:

- accepted
- rejected
- conflict
- remapped ID

## 31. Sync pull

Server returns all authorized changes after cursor. Cursors are opaque and server-generated.

Large media is not embedded in sync payloads. Sync records refer to upload session IDs.

---

# PART M — SECURITY AND PRIVACY

## 32. Security baseline

- TLS everywhere
- Encryption at rest by storage/database provider
- OIDC/OAuth2 identity
- MFA enforced for privileged roles
- Short-lived access tokens
- Refresh token/session revocation through IdP
- RBAC + organization scope + contextual ABAC
- Signed/presigned object URLs with short expiry
- Malware scanning on uploads
- Content-type validation and file-size limits
- Rate limiting
- CSRF protections where cookie auth is used
- CSP and standard secure headers
- Secrets in managed secret store, never repository
- Database backup and point-in-time recovery
- Immutable/append-only audit storage policy
- Security event monitoring

## 33. Audit events

Audit at minimum:

- login/security events (where available from IdP)
- create/update/delete of critical master data
- role/scope changes
- Job status transitions
- inspector assignments
- inspection completion/reopening
- sample custody movements
- result entry/review/approval
- accreditation changes
- report approvals/issuance/revision
- invoice posting/credit
- payment allocation
- valuation assumption changes

Audit record contains actor, action, target, timestamp, request ID, branch/entity scope, before/after diff where applicable and reason when required.

## 34. Retention and data residency

Retention must be configurable by data class, legal entity and jurisdiction after legal review. The system must support regional storage configuration, but no jurisdiction-specific legal retention period should be hard-coded without GSI legal/compliance approval.

---

# PART N — NOTIFICATIONS AND AUTOMATION

## 35. Notifications

Channels:

- in-app
- email
- push (mobile)
- future: SMS/WhatsApp only through approved integration and policy

Events:

- Job assignment
- schedule change
- inspection deadline
- sync/upload failure
- sample received
- lab result ready
- OOS result
- report awaiting approval
- report issued
- invoice overdue
- accreditation expiring
- qualification/calibration expiring

Users control non-critical notification preferences. Mandatory compliance notifications cannot be disabled by ordinary users.

---

# PART O — INTEGRATIONS

## 36. Integration architecture

All integrations live behind adapters and configuration. Initial candidates:

- Identity provider
- Email provider
- FX rate provider
- Accounting/ERP per legal entity
- Bank statement/import provider
- Object storage
- e-signature provider if required
- Existing GSI Operations application

## 37. Webhooks

Outbound webhook events use signed payloads, retries and dead-letter handling. Include unique event ID and timestamp.

---

# PART P — MIGRATION FROM EXISTING TOOLS

## 38. Migration strategy

1. Inventory existing systems/data sources.
2. Define source-of-truth per domain.
3. Build import adapters.
4. Run dry-run migration.
5. Produce reconciliation report.
6. Migrate active/open records first.
7. Migrate historical records according to agreed retention/value.
8. Preserve legacy identifiers in `external_references`/metadata.
9. Freeze legacy write window for cutover where possible.
10. Verify document hashes/counts/media counts.

Do not mass-import unverified duplicate counterparties. Use matching/reconciliation workflow.

---

# PART Q — NON-FUNCTIONAL REQUIREMENTS

## 39. Performance targets

Initial engineering targets:

- Common list/detail API p95 < 500 ms excluding external integrations.
- Search p95 < 1 second for typical authorized dataset.
- Job detail first contentful render < 2.5 seconds on normal office connection.
- Operational events visible to connected dashboards < 2 seconds.
- Direct media upload supports multi-GB videos using multipart/resume where provider allows.
- PDF generation median < 10 seconds for normal reports; asynchronous for large reports.

## 40. Availability and recovery

Targets to validate with business:

- Backoffice API availability target: 99.9% monthly.
- RPO target: ≤ 15 minutes.
- RTO target: ≤ 4 hours.
- Object storage versioning/replication according to infrastructure plan.

## 41. Observability

Every service emits:

- structured JSON logs
- trace ID/request ID
- metrics
- distributed traces for API → queue → worker paths

Operational dashboards:

- error rate
- latency
- queue depth
- upload failures
- PDF failures
- sync failures
- database health
- storage health

---

# PART R — TESTING STRATEGY

## 42. Testing layers

### Unit tests

Domain rules, calculations, workflow guards, template resolution, permission policies.

### Integration tests

PostgreSQL repositories, object storage adapter, queue/outbox, PDF renderer, authorization enforcement.

### API contract tests

OpenAPI conformance and negative authorization cases.

### End-to-end tests

Critical journeys:

1. Counterparty → Job → assignment → inspection → report → invoice.
2. Job → sample → lab result → approval → certificate.
3. Offline inspection → sync → media upload → completion.
4. Report issuance → revision → public verification.
5. Cross-branch unauthorized access attempt.
6. Expired accreditation rule blocks controlled issuance.

### Security tests

- horizontal privilege escalation
- IDOR
- upload MIME spoofing
- oversized upload
- signed URL expiry
- client-portal isolation
- permission regression suite

---

# PART S — MVP AND DELIVERY ROADMAP

## 43. Phase 0 — Discovery and validation (1–2 weeks)

Deliverables:

- Confirm legal entities/branches
- Confirm current systems and migration sources
- Confirm current document templates
- Confirm report approval workflows
- Confirm laboratory workflow/methods
- Confirm accounting integrations
- Obtain official brand assets
- Validate languages by branch

Exit criterion: signed-off master configuration workbook/data set.

## 44. Phase 1 — Platform foundation

- Monorepo
- CI/CD
- Auth/OIDC
- organization hierarchy
- users/roles/scopes
- localization
- master data
- audit/outbox
- object storage

Exit criterion: user can log in and see only authorized organization scope.

## 45. Phase 2 — CRM + Jobs + Field Operations

- counterparties
- contracts/quotes basic
- Job creation
- assignments/schedule
- inspection forms
- mobile offline support
- photo/video evidence

Exit criterion: real field inspection can be run from assignment through field completion.

## 46. Phase 3 — Samples + LIMS

- sample registry
- QR labels
- chain-of-custody
- test requests
- result entry
- QC/approval
- instruments/calibration linkage

Exit criterion: sample can move from field collection to approved lab result with full traceability.

## 47. Phase 4 — Reports + Client Portal

- template studio baseline
- PDF rendering
- multilingual templates
- approval workflow
- signatures
- QR/public verification
- client portal

Exit criterion: authorized client can receive/download an issued report generated from controlled data.

## 48. Phase 5 — Finance + Group Analytics

- invoices
- payments
- expenses
- AR
- Job profitability
- multi-currency
- management dashboard
- valuation models

Exit criterion: management can view group/branch operational and financial KPIs and trace them to source transactions.

## 49. Phase 6 — Compliance/Quality hardening and integrations

- accreditation scope engine
- controlled documents
- incidents/CAPA
- advanced accounting integration
- existing app integration/migration
- external webhooks/API clients

---

# PART T — MVP ACCEPTANCE CRITERIA

## 50. Mandatory acceptance criteria

### Organization/localization

- New country, entity and branch can be created without code deployment.
- Branch selects timezone, currencies, languages and number sequences.
- UI supports at least English, Russian and one additional configured locale without structural code changes.

### Jobs

- Authorized operator can create a Job with client, service, cargo, location and schedule.
- Job receives deterministic human-readable number.
- Inspector can be assigned and notified.
- Job status changes are audited.

### Field

- Inspector can access assigned Job on mobile.
- Inspector can complete form while offline.
- Inspector can capture photos/video and queue upload.
- Inspector can create sample with QR identifier.
- Reconnection sync does not lose data.

### Laboratory

- Lab can receive sample and create/execute test request.
- Analyst can enter results.
- Reviewer can approve results according to permissions.
- Method/specification versions are traceable.

### Documents

- System generates branded multilingual PDF.
- Final document has unique number, revision, hash and issuer.
- Issued document cannot be edited in place.
- QR/public token confirms current/superseded state without exposing private data.

### Finance

- Invoice can be generated from Job/services.
- Payment can be allocated to invoice.
- Job profitability updates.
- Group reporting converts transaction currency using stored FX rate.

### Security

- User from Branch A cannot access Branch B data without explicit scope.
- Client A cannot access Client B data.
- Privileged actions require explicit permission.
- Critical changes appear in audit log.

---

# PART U — ENGINEERING RULES FOR CODEX

## 51. Definition of done for every implementation task

A task is done only when:

1. Code compiles with strict TypeScript.
2. Lint passes.
3. Unit/integration tests for changed business behavior pass.
4. Authorization is explicitly tested.
5. Database migration is included when schema changes.
6. OpenAPI is updated when API changes.
7. i18n keys are used for user-facing UI text.
8. Audit event is added for critical state changes.
9. No secrets or production identifiers are committed.
10. README/ADR is updated if architecture changes.

## 52. Coding conventions

- Prefer clear domain names over abbreviations.
- No `any` in production TypeScript except isolated third-party adapter boundaries with justification.
- Use Zod/class-validator schemas at input boundaries depending on application layer convention.
- No business rules inside React components.
- No direct database access from controllers.
- Transactions wrap state transitions and outbox writes.
- Money uses decimal-safe types end-to-end.
- All timestamps are timezone-aware; store UTC/timestamptz, render in user/branch timezone.
- Never use translated labels as identifiers.
- Never modify issued document rows; create revision.
- Never overwrite approved lab result without an explicit amendment/revision path.

---

# PART V — INITIAL IMPLEMENTATION BACKLOG

## 53. Epic sequence for Codex

### Epic 001 — Repository bootstrap

- pnpm/Turborepo
- apps/packages structure
- TS config
- lint/format
- test framework
- Docker Compose for PostgreSQL/Redis/MinIO in dev
- CI workflow

### Epic 002 — Database foundation

- schema migration framework
- UUID extension
- organization tables
- identity projection tables
- audit/outbox
- seed currencies/languages

### Epic 003 — Auth and scope engine

- OIDC adapter
- `/me`
- permissions
- organization scope middleware/guards
- policy tests

### Epic 004 — Organization/localization admin

- legal entities
- branches
- locations
- localization profiles
- number sequences

### Epic 005 — Counterparties/contracts

- counterparty CRUD
- contacts/addresses
- client document preferences
- contracts

### Epic 006 — Jobs

- Job schema/API
- create wizard
- status transition service
- assignments
- timeline/outbox

### Epic 007 — Inspection forms

- form definition/versioning
- renderer
- responses
- start/complete

### Epic 008 — Media

- multipart upload
- checksum
- media linking
- preview worker
- evidence gallery

### Epic 009 — Mobile offline

- local SQLite
- sync queue
- push/pull protocol
- offline Job package
- media upload resume

### Epic 010 — Samples

- sample creation
- QR label
- custody events
- split/retention/disposal

### Epic 011 — LIMS

- methods/parameters/specifications
- requests/worklists
- results/reviews
- instrument/calibration validation

### Epic 012 — Reports

- templates/versions
- renderer
- approval workflow
- PDF/hash
- verification token

### Epic 013 — Client portal

- client auth mapping
- Job timeline
- documents
- invoices

### Epic 014 — Finance

- invoices/payments/expenses
- FX
- Job margin
- dashboard aggregates

### Epic 015 — Valuation

- valuation model/assumptions
- snapshot service
- scenario UI
- source traceability

### Epic 016 — Compliance

- accreditations/scopes
- rules engine
- document controlled issuance checks

---

# PART W — OPEN QUESTIONS FOR GSI STAKEHOLDERS

## 54. Must-answer questions before production rollout

1. Exact list of active legal entities, branches, offices and laboratories.
2. Which entity issues which document types today?
3. Which accreditation/certification applies to which exact service/method/location?
4. Current Job numbering rules by branch.
5. Existing report/certificate/invoice templates.
6. Required languages by branch and by major client.
7. Approval chain for each report/certificate class.
8. Which signatures are handwritten image, digital signature, e-signature or organizational seal?
9. Current accounting systems per legal entity.
10. Current CRM/operations/LIMS data sources.
11. Whether the existing General Survey Operations app should be integrated, migrated or retired.
12. Current data retention rules for reports, photos/videos and samples.
13. Sample retention and disposal policies.
14. Required offline duration and typical mobile connectivity conditions.
15. Maximum expected photo/video volumes per Job.
16. Whether GPS collection is required, optional or prohibited in specific contexts.
17. Client portal release rules for preliminary vs final results.
18. Who owns valuation assumptions and which management definition of EBITDA should be used?
19. Which FX source is approved for management reporting?
20. SSO/identity provider preference.

---

# PART X — SOURCE-OF-TRUTH AND GOVERNANCE

## 55. Configuration governance

Assign owners:

- Organization master data → Group Admin/Finance
- Service catalog → Operations + Quality
- Laboratory methods → Lab Director
- Specifications → Lab/Quality + authorized commercial owner
- Accreditation scopes → Compliance
- Document templates → Compliance/Operations + Brand
- Price books → Commercial/Finance
- Valuation assumptions → CFO/Board-authorized users

Every governed master-data change should have effective dating where business meaning changes over time.

---

# PART Y — CODEX STARTING INSTRUCTIONS

## 56. How to use this PRD with Codex

Recommended first prompt sequence:

1. Give Codex the repository and this PRD.
2. Give it `CODEX_SYSTEM_PROMPT.md` as persistent project instruction.
3. Ask it to implement **Epic 001 only**.
4. Require tests and a concise change summary.
5. Review and merge.
6. Continue epic-by-epic; do not ask it to generate the entire ERP in one pass.

The system prompt is provided as a separate file for direct reuse.

---

## 57. Final product definition

**GSI ONE** should become a single global operating layer where management can answer, in seconds:

- What Jobs are active right now?
- Where are they and who is responsible?
- What evidence has been captured?
- Where is each sample?
- Which lab results are pending or out-of-spec?
- Which reports are waiting for approval?
- Which certificates have been issued and under what controlled configuration?
- Which clients owe money?
- Which branches/services/clients are profitable?
- What is the current book equity and management-estimated enterprise/equity value?
- Can every important figure be traced back to source records and an audit trail?

If the answer to the final question is not “yes”, the platform is not finished.

