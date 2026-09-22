# GSI ONE Block 03 — Test Matrix

| ID | Area | Scenario | Expected |
|---|---|---|---|
| CP-001 | Create | scoped Sales user creates client | created + explicit visibility scope |
| CP-002 | Isolation | Branch A-only client listed by Branch B user | absent |
| CP-003 | Isolation | Branch B user GETs Branch A-only client UUID | denied/404 boundary |
| CP-004 | Isolation | body tampering adds unauthorized Branch B scope | denied |
| CP-005 | Share | user without share permission requests GROUP scope | denied |
| CP-006 | Share | authorized group admin adds GROUP scope | accepted + audited |
| CP-007 | Duplicate | same legal name/country | warning, no auto merge |
| CP-008 | Identifier | configured-unique tax identifier collision | conflict |
| CP-009 | Types | client + supplier | both retained |
| CP-010 | Deactivate | inactive client used in new quote | blocked unless override policy |
| CONTACT-001 | Primary | second active primary contact | conflict |
| CONTACT-002 | Scope | contact for unauthorized counterparty | denied |
| CONTACT-003 | Deactivate | historical quote recipient contact deactivated | historical snapshot remains |
| PREF-001 | Language | unknown language code | 422 |
| PREF-002 | Preference | legal-entity-specific preference overrides generic | resolved correctly |
| PREF-003 | Recipients | multiple TO/CC recipients | retained in order |
| SERVICE-001 | Localization | EN + RU names | one service ID, two localized values |
| SERVICE-002 | Availability | branch-disabled service selected | blocked |
| SERVICE-003 | Availability | entity-enabled service with no branch override | allowed per inheritance rule |
| CONTRACT-001 | Version | draft version edit | allowed |
| CONTRACT-002 | Version | active version edit terms | denied |
| CONTRACT-003 | Activation | approved version activates | becomes ACTIVE |
| CONTRACT-004 | Activation | new version activates | previous active SUPERSEDED |
| CONTRACT-005 | Scope | Entity A user activates Entity B contract | denied |
| CONTRACT-006 | Date | invalid effective range | 422 |
| CONTRACT-007 | Applicability | terminated contract selected after termination | blocked |
| PRICE-001 | Precedence | contract negotiated rate exists | contract rate wins |
| PRICE-002 | Precedence | client+branch book vs client+entity | client+branch wins |
| PRICE-003 | Precedence | client+entity vs branch generic | client+entity wins |
| PRICE-004 | Precedence | branch vs legal entity generic | branch wins |
| PRICE-005 | Priority | same precedence, higher priority | higher priority wins |
| PRICE-006 | Ambiguity | same precedence + same priority two matches | AMBIGUOUS_PRICE |
| PRICE-007 | Missing | no applicable price | NO_PRICE |
| PRICE-008 | Quantity | quantity outside item range | item ignored |
| PRICE-009 | Validity | price book outside date window | ignored |
| PRICE-010 | Minimum | calculated PER_UNIT below minimum | minimum charge applied |
| PRICE-011 | FX | different currency without explicit FX source | no invented conversion |
| QUOTE-001 | Numbering | parallel quote creation | no duplicate quote numbers |
| QUOTE-002 | Calculation | browser submits manipulated total | server recalculates |
| QUOTE-003 | Discount | threshold requires elevated approval | workflow blocks ordinary approver |
| QUOTE-004 | Scope | approver has permission but wrong branch scope | denied |
| QUOTE-005 | Workflow | DRAFT -> PENDING_APPROVAL | accepted with valid lines |
| QUOTE-006 | Workflow | PENDING_APPROVAL -> SENT directly | denied |
| QUOTE-007 | Workflow | APPROVED -> SENT | allowed |
| QUOTE-008 | Workflow | SENT quote line mutation | denied |
| QUOTE-009 | Accept | valid SENT quote accepted | immutable ACCEPTED |
| QUOTE-010 | Expiry | expired quote acceptance | blocked |
| QUOTE-011 | Revision | revise SENT quote | new revision, old preserved |
| QUOTE-012 | Snapshot | price book changes after quote sent | sent quote unchanged |
| QUOTE-013 | Snapshot | client preference changes after acceptance | accepted snapshot unchanged |
| AUD-001 | Audit | counterparty scope changed | actor + before/after |
| AUD-002 | Audit | contract activated | event persisted |
| AUD-003 | Audit | price-book item changed | event persisted |
| AUD-004 | Audit | quote approved | approver/decision persisted |
| CONC-001 | Versioning | stale counterparty update | 409/412 |
| CONC-002 | Versioning | stale quote draft update | 409/412 |
| E2E-001 | Commercial | client -> contract -> price -> quote -> approve -> send -> accept | passes |
