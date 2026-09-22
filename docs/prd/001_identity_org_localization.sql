-- GSI ONE Block 02
-- Identity + Organization + Localization hardening migration
-- PostgreSQL 15+
-- Apply after MASTER PRD v1.0 baseline schema.

SET search_path TO gsi, public;

-- ------------------------------------------------------------------
-- 1. OIDC issuer + subject uniqueness
-- ------------------------------------------------------------------

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS identity_issuer text;

UPDATE users
SET identity_issuer = COALESCE(identity_issuer, 'urn:gsi:legacy-or-dev')
WHERE identity_issuer IS NULL;

ALTER TABLE users
  ALTER COLUMN identity_issuer SET NOT NULL;

ALTER TABLE users
  DROP CONSTRAINT IF EXISTS users_identity_subject_key;

CREATE UNIQUE INDEX IF NOT EXISTS uq_users_identity_issuer_subject
  ON users(identity_issuer, identity_subject);

-- ------------------------------------------------------------------
-- 2. Countries as controlled reference data
-- ------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS countries (
  code              char(2) PRIMARY KEY,
  english_name      text NOT NULL,
  is_active         boolean NOT NULL DEFAULT true
);

-- Existing country columns intentionally remain char(2) for compatibility.
-- FK constraints can be applied after legacy data is validated.

-- ------------------------------------------------------------------
-- 3. Branch-level language policy
-- ------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS branch_languages (
  branch_id           uuid NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  language_code       varchar(20) NOT NULL REFERENCES languages(code),
  is_ui_enabled       boolean NOT NULL DEFAULT true,
  is_document_enabled boolean NOT NULL DEFAULT true,
  is_default          boolean NOT NULL DEFAULT false,
  display_order       smallint NOT NULL DEFAULT 100,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(branch_id, language_code),
  CHECK (NOT is_default OR is_ui_enabled)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_branch_languages_one_default
  ON branch_languages(branch_id)
  WHERE is_default = true;

CREATE INDEX IF NOT EXISTS idx_branch_languages_language
  ON branch_languages(language_code, branch_id);

-- ------------------------------------------------------------------
-- 4. Optional organization/legal-entity enabled-language policy
--    Useful for inheritance and future validation.
-- ------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS legal_entity_languages (
  legal_entity_id     uuid NOT NULL REFERENCES legal_entities(id) ON DELETE CASCADE,
  language_code       varchar(20) NOT NULL REFERENCES languages(code),
  is_enabled          boolean NOT NULL DEFAULT true,
  is_default          boolean NOT NULL DEFAULT false,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(legal_entity_id, language_code)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_legal_entity_languages_one_default
  ON legal_entity_languages(legal_entity_id)
  WHERE is_default = true;

-- ------------------------------------------------------------------
-- 5. User preference + branch selection projection
-- ------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS user_preferences (
  user_id             uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  preferred_language  varchar(20) REFERENCES languages(code),
  timezone            text,
  selected_legal_entity_id uuid REFERENCES legal_entities(id),
  selected_branch_id  uuid REFERENCES branches(id),
  settings            jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  version             integer NOT NULL DEFAULT 1
);

-- `users.preferred_language` and `users.timezone` can remain during transition.
-- Application should treat user_preferences as the new preference aggregate.

-- ------------------------------------------------------------------
-- 6. Role/permission hardening
-- ------------------------------------------------------------------

ALTER TABLE roles
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS version integer NOT NULL DEFAULT 1;

ALTER TABLE permissions
  ADD COLUMN IF NOT EXISTS domain text,
  ADD COLUMN IF NOT EXISTS resource text,
  ADD COLUMN IF NOT EXISTS action text,
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true;

CREATE INDEX IF NOT EXISTS idx_user_role_assignments_user_validity
  ON user_role_assignments(user_id, valid_from, valid_to);

CREATE INDEX IF NOT EXISTS idx_user_role_assignments_role
  ON user_role_assignments(role_id);

CREATE INDEX IF NOT EXISTS idx_user_scopes_type_value
  ON user_scopes(scope_type, scope_value);

-- ------------------------------------------------------------------
-- 7. Role assignment revocation semantics
-- ------------------------------------------------------------------

ALTER TABLE user_role_assignments
  ADD COLUMN IF NOT EXISTS revoked_at timestamptz,
  ADD COLUMN IF NOT EXISTS revoked_by uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS revoke_reason text;

-- ------------------------------------------------------------------
-- 8. Organization selected localization configuration support
-- ------------------------------------------------------------------

ALTER TABLE organizations
  ADD COLUMN IF NOT EXISTS settings jsonb NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE legal_entities
  ADD COLUMN IF NOT EXISTS settings jsonb NOT NULL DEFAULT '{}'::jsonb;

-- ------------------------------------------------------------------
-- 9. Number sequence metadata + safer administration
-- ------------------------------------------------------------------

ALTER TABLE number_sequences
  ADD COLUMN IF NOT EXISTS name text,
  ADD COLUMN IF NOT EXISTS version integer NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_number_sequences_scope
  ON number_sequences(document_type, organization_id, legal_entity_id, branch_id)
  WHERE is_active = true;

-- ------------------------------------------------------------------
-- 10. Updated-at helper (optional reusable DB helper)
-- ------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_branch_languages_updated_at ON branch_languages;
CREATE TRIGGER trg_branch_languages_updated_at
BEFORE UPDATE ON branch_languages
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_legal_entity_languages_updated_at ON legal_entity_languages;
CREATE TRIGGER trg_legal_entity_languages_updated_at
BEFORE UPDATE ON legal_entity_languages
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_user_preferences_updated_at ON user_preferences;
CREATE TRIGGER trg_user_preferences_updated_at
BEFORE UPDATE ON user_preferences
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- NOTE:
-- Application-layer validation must verify:
-- - IANA timezone values
-- - ISO country/currency/language codes
-- - selected branch belongs to selected legal entity
-- - user is authorized for selected branch
-- - exactly one branch default language before an active branch is operational
-- - scope_value semantics match scope_type
