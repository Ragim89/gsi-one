-- GSI ONE Block 03
-- Counterparties + CRM + Contracts + Pricing + Quotes
-- PostgreSQL 15+
-- Apply after baseline schema + Block 02 migration.

SET search_path TO gsi, public;

-- ============================================================
-- 1. Counterparty type normalization
-- ============================================================

CREATE TABLE IF NOT EXISTS counterparty_type_catalog (
  code        text PRIMARY KEY,
  name        text NOT NULL,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS counterparty_type_assignments (
  counterparty_id uuid NOT NULL REFERENCES counterparties(id) ON DELETE CASCADE,
  type_code       text NOT NULL REFERENCES counterparty_type_catalog(code),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      uuid REFERENCES users(id),
  PRIMARY KEY(counterparty_id, type_code)
);

-- Backfill normalized assignments from the baseline text[] column.
INSERT INTO counterparty_type_assignments(counterparty_id, type_code)
SELECT c.id, t.type_code
FROM counterparties c
CROSS JOIN LATERAL unnest(c.counterparty_types) AS t(type_code)
JOIN counterparty_type_catalog catalog ON catalog.code = t.type_code
ON CONFLICT DO NOTHING;

-- `counterparties.counterparty_types` is retained only for transitional compatibility.
-- New domain logic must use counterparty_type_assignments as source of truth.

-- ============================================================
-- 2. Counterparty identifiers + visibility
-- ============================================================

CREATE TABLE IF NOT EXISTS counterparty_identifiers (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  counterparty_id   uuid NOT NULL REFERENCES counterparties(id) ON DELETE CASCADE,
  identifier_type   text NOT NULL,
  country_code      char(2),
  value             text NOT NULL,
  normalized_value  text NOT NULL,
  is_primary        boolean NOT NULL DEFAULT false,
  is_active         boolean NOT NULL DEFAULT true,
  metadata          jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        uuid REFERENCES users(id),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        uuid REFERENCES users(id),
  version           integer NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_counterparty_identifiers_lookup
  ON counterparty_identifiers(identifier_type, country_code, normalized_value)
  WHERE is_active = true;

CREATE UNIQUE INDEX IF NOT EXISTS uq_counterparty_identifier_primary_type
  ON counterparty_identifiers(counterparty_id, identifier_type)
  WHERE is_primary = true AND is_active = true;

CREATE TABLE IF NOT EXISTS counterparty_scopes (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  counterparty_id  uuid NOT NULL REFERENCES counterparties(id) ON DELETE CASCADE,
  scope_type       text NOT NULL CHECK (scope_type IN ('GROUP','COUNTRY','LEGAL_ENTITY','BRANCH')),
  scope_value      text NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       uuid REFERENCES users(id),
  UNIQUE(counterparty_id, scope_type, scope_value)
);

CREATE INDEX IF NOT EXISTS idx_counterparty_scopes_resolve
  ON counterparty_scopes(scope_type, scope_value, counterparty_id);

-- ============================================================
-- 3. Counterparty entity-specific commercial profile
-- ============================================================

CREATE TABLE IF NOT EXISTS counterparty_entity_profiles (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  counterparty_id     uuid NOT NULL REFERENCES counterparties(id) ON DELETE CASCADE,
  legal_entity_id     uuid NOT NULL REFERENCES legal_entities(id),
  default_branch_id   uuid REFERENCES branches(id),
  account_manager_id  uuid REFERENCES employees(id),
  account_code        text,
  commercial_status   text NOT NULL DEFAULT 'ACTIVE'
    CHECK (commercial_status IN ('PROSPECT','ACTIVE','ON_HOLD','INACTIVE')),
  default_currency    char(3) REFERENCES currencies(code),
  payment_term_days   integer CHECK (payment_term_days IS NULL OR payment_term_days >= 0),
  po_required         boolean NOT NULL DEFAULT false,
  consolidate_invoices boolean NOT NULL DEFAULT false,
  credit_limit        numeric(20,6),
  credit_hold         boolean NOT NULL DEFAULT false,
  tax_settings        jsonb NOT NULL DEFAULT '{}'::jsonb,
  settings            jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES users(id),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          uuid REFERENCES users(id),
  version             integer NOT NULL DEFAULT 1,
  UNIQUE(counterparty_id, legal_entity_id),
  CHECK (credit_limit IS NULL OR credit_limit >= 0)
);

CREATE INDEX IF NOT EXISTS idx_counterparty_entity_profiles_entity
  ON counterparty_entity_profiles(legal_entity_id, counterparty_id);

-- ============================================================
-- 4. Contacts hardening
-- ============================================================

ALTER TABLE counterparty_contacts
  ADD COLUMN IF NOT EXISTS department text,
  ADD COLUMN IF NOT EXISTS timezone text,
  ADD COLUMN IF NOT EXISTS communication_settings jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS version integer NOT NULL DEFAULT 1;

CREATE UNIQUE INDEX IF NOT EXISTS uq_counterparty_one_primary_contact
  ON counterparty_contacts(counterparty_id)
  WHERE is_primary = true AND is_active = true;

CREATE INDEX IF NOT EXISTS idx_counterparty_contacts_email
  ON counterparty_contacts(email)
  WHERE email IS NOT NULL AND is_active = true;

-- ============================================================
-- 5. Structured addresses
-- ============================================================

ALTER TABLE counterparty_addresses
  ALTER COLUMN address SET DEFAULT '{}'::jsonb;

ALTER TABLE counterparty_addresses
  ADD COLUMN IF NOT EXISTS label text,
  ADD COLUMN IF NOT EXISTS line1 text,
  ADD COLUMN IF NOT EXISTS line2 text,
  ADD COLUMN IF NOT EXISTS city text,
  ADD COLUMN IF NOT EXISTS region text,
  ADD COLUMN IF NOT EXISTS postal_code text,
  ADD COLUMN IF NOT EXISTS country_code char(2),
  ADD COLUMN IF NOT EXISTS latitude numeric(10,7),
  ADD COLUMN IF NOT EXISTS longitude numeric(10,7),
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS version integer NOT NULL DEFAULT 1;

ALTER TABLE counterparty_addresses
  DROP CONSTRAINT IF EXISTS counterparty_addresses_address_type_check;

ALTER TABLE counterparty_addresses
  ADD CONSTRAINT counterparty_addresses_address_type_check
  CHECK (address_type IN ('REGISTERED','BILLING','SHIPPING','SITE','WAREHOUSE','PORT','OTHER'));

CREATE UNIQUE INDEX IF NOT EXISTS uq_counterparty_default_address_type
  ON counterparty_addresses(counterparty_id, address_type)
  WHERE is_default = true AND is_active = true;

-- ============================================================
-- 6. Client document and billing preferences
-- ============================================================

CREATE TABLE IF NOT EXISTS counterparty_document_preferences (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  counterparty_id     uuid NOT NULL REFERENCES counterparties(id) ON DELETE CASCADE,
  legal_entity_id     uuid REFERENCES legal_entities(id),
  document_type       text NOT NULL,
  primary_language    varchar(20) REFERENCES languages(code),
  additional_languages text[] NOT NULL DEFAULT ARRAY[]::text[],
  filename_pattern    text,
  portal_delivery     boolean NOT NULL DEFAULT true,
  email_delivery      boolean NOT NULL DEFAULT false,
  auto_deliver_after_approval boolean NOT NULL DEFAULT false,
  preferred_template_key text,
  settings            jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES users(id),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          uuid REFERENCES users(id),
  version             integer NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_counterparty_doc_pref_scope
  ON counterparty_document_preferences(
    counterparty_id,
    COALESCE(legal_entity_id, '00000000-0000-0000-0000-000000000000'::uuid),
    document_type
  );

CREATE TABLE IF NOT EXISTS counterparty_document_recipients (
  preference_id      uuid NOT NULL REFERENCES counterparty_document_preferences(id) ON DELETE CASCADE,
  contact_id         uuid NOT NULL REFERENCES counterparty_contacts(id),
  recipient_role     text NOT NULL DEFAULT 'TO' CHECK (recipient_role IN ('TO','CC','BCC')),
  display_order      smallint NOT NULL DEFAULT 100,
  created_at         timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(preference_id, contact_id, recipient_role)
);

CREATE TABLE IF NOT EXISTS counterparty_billing_profiles (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  counterparty_id      uuid NOT NULL REFERENCES counterparties(id) ON DELETE CASCADE,
  legal_entity_id      uuid NOT NULL REFERENCES legal_entities(id),
  currency             char(3) REFERENCES currencies(code),
  payment_term_days    integer CHECK (payment_term_days IS NULL OR payment_term_days >= 0),
  po_required          boolean NOT NULL DEFAULT false,
  consolidate_invoices boolean NOT NULL DEFAULT false,
  billing_address_id   uuid REFERENCES counterparty_addresses(id),
  invoice_contact_id   uuid REFERENCES counterparty_contacts(id),
  client_reference_required boolean NOT NULL DEFAULT false,
  credit_limit         numeric(20,6),
  credit_hold          boolean NOT NULL DEFAULT false,
  tax_settings         jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           uuid REFERENCES users(id),
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           uuid REFERENCES users(id),
  version              integer NOT NULL DEFAULT 1,
  UNIQUE(counterparty_id, legal_entity_id),
  CHECK (credit_limit IS NULL OR credit_limit >= 0)
);

-- ============================================================
-- 7. CRM activity timeline
-- ============================================================

CREATE TABLE IF NOT EXISTS crm_activities (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id  uuid NOT NULL REFERENCES organizations(id),
  counterparty_id  uuid NOT NULL REFERENCES counterparties(id) ON DELETE CASCADE,
  contact_id       uuid REFERENCES counterparty_contacts(id),
  contract_id      uuid REFERENCES contracts(id),
  quote_id         uuid REFERENCES quotes(id),
  activity_type    text NOT NULL CHECK (activity_type IN ('NOTE','CALL','EMAIL','MEETING','TASK','FOLLOW_UP')),
  subject          text,
  body             text,
  status           text NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','DONE','CANCELLED')),
  occurred_at      timestamptz,
  due_at           timestamptz,
  owner_user_id    uuid REFERENCES users(id),
  metadata         jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       uuid REFERENCES users(id),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       uuid REFERENCES users(id),
  version          integer NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_crm_activities_counterparty_time
  ON crm_activities(counterparty_id, COALESCE(occurred_at, created_at) DESC);

CREATE INDEX IF NOT EXISTS idx_crm_activities_owner_due
  ON crm_activities(owner_user_id, due_at)
  WHERE status = 'OPEN';

-- ============================================================
-- 8. Service localization and availability
-- ============================================================

ALTER TABLE service_catalog
  ADD COLUMN IF NOT EXISTS version integer NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES users(id);

CREATE TABLE IF NOT EXISTS service_localizations (
  service_id       uuid NOT NULL REFERENCES service_catalog(id) ON DELETE CASCADE,
  language_code    varchar(20) NOT NULL REFERENCES languages(code),
  name             text NOT NULL,
  short_name       text,
  description      text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(service_id, language_code)
);

CREATE TABLE IF NOT EXISTS service_availability (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id       uuid NOT NULL REFERENCES service_catalog(id) ON DELETE CASCADE,
  legal_entity_id  uuid NOT NULL REFERENCES legal_entities(id),
  branch_id        uuid REFERENCES branches(id),
  is_sellable      boolean NOT NULL DEFAULT true,
  is_operational   boolean NOT NULL DEFAULT true,
  local_default_unit text,
  effective_from   date,
  effective_to     date,
  settings         jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  version          integer NOT NULL DEFAULT 1,
  CHECK (effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_service_availability_scope
  ON service_availability(
    service_id,
    legal_entity_id,
    COALESCE(branch_id, '00000000-0000-0000-0000-000000000000'::uuid)
  );

CREATE INDEX IF NOT EXISTS idx_service_availability_entity_branch
  ON service_availability(legal_entity_id, branch_id, service_id);

-- ============================================================
-- 9. Contract versioning
-- ============================================================

CREATE TABLE IF NOT EXISTS contract_versions (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  contract_id           uuid NOT NULL REFERENCES contracts(id) ON DELETE RESTRICT,
  version_no            integer NOT NULL,
  status                text NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT','PENDING_APPROVAL','APPROVED','ACTIVE','SUPERSEDED','REJECTED')),
  effective_from        date,
  effective_to          date,
  signed_at             date,
  signed_by_gsi         text,
  signed_by_counterparty text,
  billing_terms         jsonb NOT NULL DEFAULT '{}'::jsonb,
  operational_terms     jsonb NOT NULL DEFAULT '{}'::jsonb,
  client_requirements   jsonb NOT NULL DEFAULT '{}'::jsonb,
  governing_law         text,
  source_file_reference jsonb NOT NULL DEFAULT '{}'::jsonb,
  approved_at           timestamptz,
  approved_by           uuid REFERENCES users(id),
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            uuid REFERENCES users(id),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            uuid REFERENCES users(id),
  row_version            integer NOT NULL DEFAULT 1,
  UNIQUE(contract_id, version_no),
  CHECK (effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_contract_one_active_version
  ON contract_versions(contract_id)
  WHERE status = 'ACTIVE';

CREATE TABLE IF NOT EXISTS contract_services (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  contract_version_id uuid NOT NULL REFERENCES contract_versions(id) ON DELETE CASCADE,
  service_id          uuid NOT NULL REFERENCES service_catalog(id),
  unit_code           text,
  negotiated_unit_price numeric(20,6),
  minimum_charge      numeric(20,6),
  price_book_id       uuid REFERENCES price_books(id),
  sla                 jsonb NOT NULL DEFAULT '{}'::jsonb,
  client_instructions jsonb NOT NULL DEFAULT '{}'::jsonb,
  conditions          jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES users(id),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          uuid REFERENCES users(id),
  version             integer NOT NULL DEFAULT 1,
  CHECK (negotiated_unit_price IS NULL OR negotiated_unit_price >= 0),
  CHECK (minimum_charge IS NULL OR minimum_charge >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_contract_services_version_service_unit
  ON contract_services(contract_version_id, service_id, COALESCE(unit_code, ''));

-- ============================================================
-- 10. Price-book hardening
-- ============================================================

ALTER TABLE price_books
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'DRAFT',
  ADD COLUMN IF NOT EXISTS priority integer NOT NULL DEFAULT 100,
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES users(id);

-- Map any pre-Block-03 rows once. `status` is the new domain source of truth.
UPDATE price_books
SET status = CASE WHEN is_active THEN 'ACTIVE' ELSE 'RETIRED' END
WHERE status = 'DRAFT';

ALTER TABLE price_books
  ALTER COLUMN is_active SET DEFAULT false;

ALTER TABLE price_books
  DROP CONSTRAINT IF EXISTS price_books_status_check;

ALTER TABLE price_books
  ADD CONSTRAINT price_books_status_check
  CHECK (status IN ('DRAFT','ACTIVE','RETIRED'));

CREATE INDEX IF NOT EXISTS idx_price_books_resolution
  ON price_books(counterparty_id, legal_entity_id, branch_id, status, valid_from, valid_to, priority);

-- Baseline uniqueness allowed only one service/unit row and therefore prevented
-- quantity tiers. Block 03 resolver must allow multiple conditional rows.
ALTER TABLE price_book_items
  DROP CONSTRAINT IF EXISTS price_book_items_price_book_id_service_id_unit_code_key;

ALTER TABLE price_book_items
  ADD COLUMN IF NOT EXISTS pricing_method text NOT NULL DEFAULT 'PER_UNIT',
  ADD COLUMN IF NOT EXISTS min_quantity numeric(20,6),
  ADD COLUMN IF NOT EXISTS max_quantity numeric(20,6),
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS version integer NOT NULL DEFAULT 1;

ALTER TABLE price_book_items
  DROP CONSTRAINT IF EXISTS price_book_items_pricing_method_check;

ALTER TABLE price_book_items
  ADD CONSTRAINT price_book_items_pricing_method_check
  CHECK (pricing_method IN ('FIXED','PER_UNIT'));

ALTER TABLE price_book_items
  DROP CONSTRAINT IF EXISTS price_book_items_quantity_range_check;

ALTER TABLE price_book_items
  ADD CONSTRAINT price_book_items_quantity_range_check
  CHECK (max_quantity IS NULL OR min_quantity IS NULL OR max_quantity >= min_quantity);

ALTER TABLE price_book_items
  DROP CONSTRAINT IF EXISTS price_book_items_nonnegative_check;

ALTER TABLE price_book_items
  ADD CONSTRAINT price_book_items_nonnegative_check
  CHECK (unit_price >= 0 AND (minimum_charge IS NULL OR minimum_charge >= 0));

CREATE INDEX IF NOT EXISTS idx_price_book_items_resolution
  ON price_book_items(price_book_id, service_id, unit_code, min_quantity, max_quantity);

-- ============================================================
-- 11. Quote revision/approval/snapshots
-- ============================================================

ALTER TABLE quotes
  ADD COLUMN IF NOT EXISTS revision_no integer NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS owner_user_id uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS contract_version_id uuid REFERENCES contract_versions(id),
  ADD COLUMN IF NOT EXISTS submitted_at timestamptz,
  ADD COLUMN IF NOT EXISTS approved_at timestamptz,
  ADD COLUMN IF NOT EXISTS sent_at timestamptz,
  ADD COLUMN IF NOT EXISTS accepted_at timestamptz,
  ADD COLUMN IF NOT EXISTS rejected_at timestamptz,
  ADD COLUMN IF NOT EXISTS pricing_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS client_preferences_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb;

CREATE TABLE IF NOT EXISTS quote_revisions (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  root_quote_id     uuid NOT NULL REFERENCES quotes(id) ON DELETE RESTRICT,
  quote_id          uuid NOT NULL UNIQUE REFERENCES quotes(id) ON DELETE RESTRICT,
  revision_no       integer NOT NULL,
  previous_quote_id uuid REFERENCES quotes(id),
  reason            text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        uuid REFERENCES users(id),
  UNIQUE(root_quote_id, revision_no)
);

CREATE TABLE IF NOT EXISTS quote_approvals (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id          uuid NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
  step_no           integer NOT NULL DEFAULT 1,
  approver_user_id  uuid NOT NULL REFERENCES users(id),
  decision          text NOT NULL CHECK (decision IN ('APPROVED','REJECTED')),
  decided_at        timestamptz NOT NULL DEFAULT now(),
  comment           text,
  metadata          jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_quote_approvals_quote
  ON quote_approvals(quote_id, step_no, decided_at);

ALTER TABLE quote_items
  ADD COLUMN IF NOT EXISTS service_code_snapshot text,
  ADD COLUMN IF NOT EXISTS service_name_snapshot text,
  ADD COLUMN IF NOT EXISTS minimum_charge_applied numeric(20,6),
  ADD COLUMN IF NOT EXISTS discount_percent numeric(9,6),
  ADD COLUMN IF NOT EXISTS tax_code_snapshot text,
  ADD COLUMN IF NOT EXISTS tax_rate_snapshot numeric(9,6),
  ADD COLUMN IF NOT EXISTS pricing_source_type text,
  ADD COLUMN IF NOT EXISTS pricing_source_id uuid,
  ADD COLUMN IF NOT EXISTS pricing_resolution jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS version integer NOT NULL DEFAULT 1;

ALTER TABLE quote_items
  DROP CONSTRAINT IF EXISTS quote_items_nonnegative_amounts_check;

ALTER TABLE quote_items
  ADD CONSTRAINT quote_items_nonnegative_amounts_check
  CHECK (
    quantity >= 0
    AND unit_price >= 0
    AND discount_amount >= 0
    AND tax_amount >= 0
    AND line_total >= 0
    AND (minimum_charge_applied IS NULL OR minimum_charge_applied >= 0)
  );

-- ============================================================
-- 12. Counterparty base hardening
-- ============================================================

ALTER TABLE counterparties
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'ACTIVE',
  ADD COLUMN IF NOT EXISTS risk_status text NOT NULL DEFAULT 'NORMAL';

ALTER TABLE counterparties
  DROP CONSTRAINT IF EXISTS counterparties_status_check;

ALTER TABLE counterparties
  ADD CONSTRAINT counterparties_status_check
  CHECK (status IN ('PROSPECT','ACTIVE','ON_HOLD','INACTIVE'));

ALTER TABLE counterparties
  DROP CONSTRAINT IF EXISTS counterparties_risk_status_check;

ALTER TABLE counterparties
  ADD CONSTRAINT counterparties_risk_status_check
  CHECK (risk_status IN ('NORMAL','REVIEW','RESTRICTED'));

CREATE INDEX IF NOT EXISTS idx_counterparties_org_active_name
  ON counterparties(organization_id, is_active, lower(legal_name));

CREATE UNIQUE INDEX IF NOT EXISTS uq_counterparties_org_code
  ON counterparties(organization_id, lower(code))
  WHERE code IS NOT NULL;

-- ============================================================
-- 13. Updated-at triggers using Block 02 helper
-- ============================================================

DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'counterparty_identifiers',
    'counterparty_entity_profiles',
    'counterparty_contacts',
    'counterparty_addresses',
    'counterparty_document_preferences',
    'counterparty_billing_profiles',
    'crm_activities',
    'service_localizations',
    'service_availability',
    'contract_versions',
    'contract_services',
    'price_book_items'
  ]
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_%I_updated_at ON %I', t, t);
    EXECUTE format(
      'CREATE TRIGGER trg_%I_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
      t, t
    );
  END LOOP;
END $$;

-- NOTE:
-- Application-layer workflow guards still enforce immutable ACTIVE contract versions,
-- quote state transitions, pricing ambiguity rules and scope authorization.
