# GSI ONE Block 02 — Test Matrix

| ID | Area | Scenario | Expected |
|---|---|---|---|
| AUTH-001 | OIDC | valid issuer/sub maps to active user | 200 /me |
| AUTH-002 | OIDC | unknown issuer/sub | configured onboarding behavior; never implicit admin |
| AUTH-003 | Status | suspended user + valid token | denied |
| AUTH-004 | Roles | active assignment in validity window | contributes access |
| AUTH-005 | Roles | expired assignment | ignored |
| AUTH-006 | Roles | revoked assignment | ignored |
| AUTH-007 | Scope | permission + Branch A scope | Branch A allowed |
| AUTH-008 | Scope | Branch A user direct GET Branch B | denied/404 boundary |
| AUTH-009 | Scope | Branch A user list branches | Branch B absent |
| AUTH-010 | Scope | Branch A user submits Branch B ID in body | denied |
| AUTH-011 | Scope | legal entity scope | child branches allowed |
| AUTH-012 | Scope | legal entity scope | sibling entity denied |
| AUTH-013 | Scope | country scope | matching country allowed only |
| AUTH-014 | Permission | scope but no read permission | denied |
| AUTH-015 | Permission | manage permission but no scope | denied |
| AUTH-016 | Executive | group read permission | reads all in group |
| AUTH-017 | Executive | group read without manage | mutation denied |
| LOC-001 | Branch language | one default | accepted |
| LOC-002 | Branch language | no default for active branch | validation error |
| LOC-003 | Branch language | two defaults | DB/app rejects |
| LOC-004 | Branch language | default but UI disabled | rejects |
| LOC-005 | Locale | valid IANA timezone | accepted |
| LOC-006 | Locale | invalid timezone | 422 |
| LOC-007 | UI | Arabic locale | RTL direction enabled |
| ORG-001 | Legal entity | duplicate code in same org | conflict |
| ORG-002 | Branch | duplicate code in same entity | conflict |
| ORG-003 | Deactivation | inactive branch remains queryable in history/admin | no delete |
| ORG-004 | Version | stale If-Match/version | 412/409 |
| SEQ-001 | Sequence | 100 parallel allocations | 100 unique values |
| SEQ-002 | Sequence | preview | counter unchanged |
| SEQ-003 | Sequence | YEARLY boundary | resets once |
| SEQ-004 | Sequence | MONTHLY boundary | resets once |
| AUD-001 | Audit | role assignment created | audit row + actor/request ID |
| AUD-002 | Audit | scope revoked | before/after + reason |
| AUD-003 | Audit | branch languages changed | policy diff recorded |
| AUD-004 | Audit | sequence config changed | audited |
