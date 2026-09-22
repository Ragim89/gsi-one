-- GSI ONE Block 02 seed data
SET search_path TO gsi, public;

INSERT INTO languages(code, english_name, native_name, is_rtl, is_active) VALUES
  ('en', 'English', 'English', false, true),
  ('tr', 'Turkish', 'Türkçe', false, true),
  ('ru', 'Russian', 'Русский', false, true),
  ('kk', 'Kazakh', 'Қазақша', false, true),
  ('uk', 'Ukrainian', 'Українська', false, true),
  ('ro', 'Romanian', 'Română', false, true),
  ('uz', 'Uzbek', 'Oʻzbekcha', false, true),
  ('it', 'Italian', 'Italiano', false, true),
  ('ar', 'Arabic', 'العربية', true, true)
ON CONFLICT (code) DO UPDATE SET
  english_name = EXCLUDED.english_name,
  native_name = EXCLUDED.native_name,
  is_rtl = EXCLUDED.is_rtl,
  is_active = EXCLUDED.is_active;

INSERT INTO currencies(code, name, minor_units, is_active) VALUES
  ('EUR', 'Euro', 2, true),
  ('USD', 'US Dollar', 2, true),
  ('TRY', 'Turkish Lira', 2, true),
  ('KZT', 'Kazakhstani Tenge', 2, true),
  ('UZS', 'Uzbekistani Som', 2, true),
  ('RON', 'Romanian Leu', 2, true),
  ('UAH', 'Ukrainian Hryvnia', 2, true),
  ('AED', 'UAE Dirham', 2, true)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  minor_units = EXCLUDED.minor_units,
  is_active = EXCLUDED.is_active;

INSERT INTO countries(code, english_name, is_active) VALUES
  ('TR', 'Türkiye', true),
  ('RO', 'Romania', true),
  ('UA', 'Ukraine', true),
  ('UZ', 'Uzbekistan', true),
  ('KZ', 'Kazakhstan', true),
  ('AE', 'United Arab Emirates', true),
  ('IT', 'Italy', true)
ON CONFLICT (code) DO UPDATE SET
  english_name = EXCLUDED.english_name,
  is_active = EXCLUDED.is_active;

INSERT INTO permissions(code, description, domain, resource, action, is_active) VALUES
  ('admin.user.read', 'Read user accounts', 'admin', 'user', 'read', true),
  ('admin.user.manage', 'Manage user status/profile linkage', 'admin', 'user', 'manage', true),
  ('admin.role.read', 'Read roles and assignments', 'admin', 'role', 'read', true),
  ('admin.role.manage', 'Manage roles and role permissions', 'admin', 'role', 'manage', true),
  ('admin.permission.read', 'Read permission catalog', 'admin', 'permission', 'read', true),
  ('admin.scope.manage', 'Manage role assignment scopes', 'admin', 'scope', 'manage', true),
  ('organization.group.read', 'Read organization/group configuration', 'organization', 'group', 'read', true),
  ('organization.group.manage', 'Manage organization/group configuration', 'organization', 'group', 'manage', true),
  ('organization.legal_entity.read', 'Read legal entities', 'organization', 'legal_entity', 'read', true),
  ('organization.legal_entity.manage', 'Manage legal entities', 'organization', 'legal_entity', 'manage', true),
  ('organization.branch.read', 'Read branches', 'organization', 'branch', 'read', true),
  ('organization.branch.manage', 'Manage branches', 'organization', 'branch', 'manage', true),
  ('organization.location.read', 'Read locations', 'organization', 'location', 'read', true),
  ('organization.location.manage', 'Manage locations', 'organization', 'location', 'manage', true),
  ('organization.localization.read', 'Read localization configuration', 'organization', 'localization', 'read', true),
  ('organization.localization.manage', 'Manage localization configuration', 'organization', 'localization', 'manage', true),
  ('organization.sequence.read', 'Read number sequence configuration', 'organization', 'sequence', 'read', true),
  ('organization.sequence.manage', 'Manage number sequence configuration', 'organization', 'sequence', 'manage', true),
  ('audit.event.read', 'Read authorized audit events', 'audit', 'event', 'read', true)
ON CONFLICT (code) DO UPDATE SET
  description = EXCLUDED.description,
  domain = EXCLUDED.domain,
  resource = EXCLUDED.resource,
  action = EXCLUDED.action,
  is_active = EXCLUDED.is_active;

INSERT INTO roles(code, name, description, is_system, is_active) VALUES
  ('GROUP_SUPER_ADMIN', 'Group Super Admin', 'Platform and group administration with explicit permissions.', true, true),
  ('GROUP_CEO_VIEWER', 'Group CEO / Board Viewer', 'Group-wide executive read access.', true, true),
  ('GROUP_CFO', 'Group CFO', 'Group finance administration and reporting.', true, true),
  ('GROUP_COO', 'Group COO', 'Group operations administration and reporting.', true, true),
  ('GROUP_COMPLIANCE_DIRECTOR', 'Group Quality / Compliance Director', 'Group compliance administration.', true, true),
  ('COUNTRY_DIRECTOR', 'Country Director', 'Country-scoped management.', true, true),
  ('BRANCH_MANAGER', 'Branch Manager', 'Branch-scoped operational management.', true, true),
  ('OPERATIONS_MANAGER', 'Operations Manager / Dispatcher', 'Operations management within scope.', true, true),
  ('INSPECTOR', 'Inspector', 'Assigned operational work.', true, true),
  ('LAB_DIRECTOR', 'Lab Director', 'Laboratory administration within scope.', true, true),
  ('LAB_ANALYST', 'Lab Analyst', 'Laboratory execution within assignment.', true, true),
  ('FINANCE_MANAGER', 'Finance Manager', 'Finance management within scope.', true, true),
  ('ACCOUNTANT', 'Accountant', 'Accounting operations within scope.', true, true),
  ('SALES_CRM', 'Sales / CRM', 'Commercial operations within scope.', true, true),
  ('HR_ADMIN', 'HR / People Admin', 'People administration within scope.', true, true),
  ('COMPLIANCE_AUDITOR', 'Compliance Auditor', 'Read-only compliance and audit access.', true, true),
  ('CLIENT_USER', 'Client User', 'External counterparty-scoped access.', true, true),
  ('INTEGRATION_SERVICE', 'Integration Service Account', 'API-only service identity with explicit scope.', true, true)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  is_system = EXCLUDED.is_system,
  is_active = EXCLUDED.is_active;

-- Block-02-only permission mapping for GROUP_SUPER_ADMIN.
-- Later module migrations extend permissions intentionally rather than relying on wildcard bypass.
INSERT INTO role_permissions(role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.code = 'GROUP_SUPER_ADMIN'
  AND p.is_active = true
ON CONFLICT DO NOTHING;

-- Read-only organizational visibility for executive viewer.
INSERT INTO role_permissions(role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
  'organization.group.read',
  'organization.legal_entity.read',
  'organization.branch.read',
  'organization.location.read',
  'organization.localization.read'
)
WHERE r.code = 'GROUP_CEO_VIEWER'
ON CONFLICT DO NOTHING;

-- Typical branch-manager access for Block 02.
INSERT INTO role_permissions(role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
  'organization.legal_entity.read',
  'organization.branch.read',
  'organization.location.read',
  'organization.location.manage',
  'organization.localization.read',
  'organization.sequence.read'
)
WHERE r.code = 'BRANCH_MANAGER'
ON CONFLICT DO NOTHING;

-- Auditor has read-only access to organization and audit events.
INSERT INTO role_permissions(role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
  'organization.group.read',
  'organization.legal_entity.read',
  'organization.branch.read',
  'organization.location.read',
  'organization.localization.read',
  'audit.event.read'
)
WHERE r.code = 'COMPLIANCE_AUDITOR'
ON CONFLICT DO NOTHING;
