-- GSI ONE Block 03 seed
-- Idempotent seed for counterparty types and Block 03 permissions.

SET search_path TO gsi, public;

INSERT INTO counterparty_type_catalog(code, name)
VALUES
  ('CLIENT','Client'),
  ('SUPPLIER','Supplier'),
  ('AGENT','Agent'),
  ('SUBCONTRACTOR','Subcontractor'),
  ('EXTERNAL_LAB','External Laboratory'),
  ('CARRIER','Carrier'),
  ('BROKER','Broker'),
  ('WAREHOUSE_OPERATOR','Warehouse Operator'),
  ('OTHER','Other')
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    is_active = true;

-- Assumes Block 02 permissions table supports code + descriptive fields.
INSERT INTO permissions(code, description, domain, resource, action, is_active)
VALUES
  ('crm.counterparty.read','Read counterparties','crm','counterparty','read',true),
  ('crm.counterparty.create','Create counterparties','crm','counterparty','create',true),
  ('crm.counterparty.manage','Manage counterparties','crm','counterparty','manage',true),
  ('crm.counterparty.share','Share counterparties across scopes','crm','counterparty','share',true),
  ('crm.counterparty.identifiers.manage','Manage counterparty identifiers','crm','counterparty.identifiers','manage',true),
  ('crm.counterparty.preferences.manage','Manage counterparty preferences','crm','counterparty.preferences','manage',true),
  ('crm.contact.read','Read contacts','crm','contact','read',true),
  ('crm.contact.manage','Manage contacts','crm','contact','manage',true),
  ('crm.activity.read','Read CRM activities','crm','activity','read',true),
  ('crm.activity.manage','Manage CRM activities','crm','activity','manage',true),
  ('crm.service.read','Read services','crm','service','read',true),
  ('crm.service.manage','Manage services','crm','service','manage',true),
  ('crm.service.availability_manage','Manage service availability','crm','service.availability','manage',true),
  ('crm.contract.read','Read contracts','crm','contract','read',true),
  ('crm.contract.create','Create contracts','crm','contract','create',true),
  ('crm.contract.manage','Manage contracts','crm','contract','manage',true),
  ('crm.contract.approve','Approve contract versions','crm','contract','approve',true),
  ('crm.contract.activate','Activate contract versions','crm','contract','activate',true),
  ('crm.price_book.read','Read price books','crm','price_book','read',true),
  ('crm.price_book.manage','Manage price books','crm','price_book','manage',true),
  ('crm.price.resolve','Resolve commercial price','crm','price','resolve',true),
  ('crm.quote.read','Read quotes','crm','quote','read',true),
  ('crm.quote.create','Create quotes','crm','quote','create',true),
  ('crm.quote.manage','Manage draft quotes','crm','quote','manage',true),
  ('crm.quote.approve','Approve quotes','crm','quote','approve',true),
  ('crm.quote.discount_approve','Approve quote discount threshold exception','crm','quote.discount','approve',true),
  ('crm.quote.send','Mark/send quote through future delivery adapter','crm','quote','send',true),
  ('crm.quote.accept','Record quote acceptance','crm','quote','accept',true)
ON CONFLICT (code) DO UPDATE
SET description = EXCLUDED.description,
    domain = EXCLUDED.domain,
    resource = EXCLUDED.resource,
    action = EXCLUDED.action,
    is_active = true;

-- Group Super Admin receives every active Block 03 permission explicitly.
INSERT INTO role_permissions(role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code LIKE 'crm.%'
WHERE r.code = 'GROUP_SUPER_ADMIN'
  AND p.is_active = true
ON CONFLICT DO NOTHING;

-- Sales / CRM owns routine commercial work but not high-risk approval/activation rights.
INSERT INTO role_permissions(role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
  'crm.counterparty.read',
  'crm.counterparty.create',
  'crm.counterparty.manage',
  'crm.counterparty.identifiers.manage',
  'crm.counterparty.preferences.manage',
  'crm.contact.read',
  'crm.contact.manage',
  'crm.activity.read',
  'crm.activity.manage',
  'crm.service.read',
  'crm.contract.read',
  'crm.contract.create',
  'crm.contract.manage',
  'crm.price_book.read',
  'crm.price.resolve',
  'crm.quote.read',
  'crm.quote.create',
  'crm.quote.manage',
  'crm.quote.send'
)
WHERE r.code = 'SALES_CRM'
ON CONFLICT DO NOTHING;

-- Country and branch management can perform commercial approvals within their scopes.
INSERT INTO role_permissions(role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
  'crm.counterparty.read',
  'crm.counterparty.create',
  'crm.counterparty.manage',
  'crm.counterparty.preferences.manage',
  'crm.contact.read',
  'crm.contact.manage',
  'crm.activity.read',
  'crm.activity.manage',
  'crm.service.read',
  'crm.contract.read',
  'crm.contract.create',
  'crm.contract.manage',
  'crm.contract.approve',
  'crm.contract.activate',
  'crm.price_book.read',
  'crm.price_book.manage',
  'crm.price.resolve',
  'crm.quote.read',
  'crm.quote.create',
  'crm.quote.manage',
  'crm.quote.approve',
  'crm.quote.discount_approve',
  'crm.quote.send',
  'crm.quote.accept'
)
WHERE r.code IN ('COUNTRY_DIRECTOR','BRANCH_MANAGER')
ON CONFLICT DO NOTHING;

-- Operations needs read access to commercial context before Block 04 Jobs.
INSERT INTO role_permissions(role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
  'crm.counterparty.read',
  'crm.contact.read',
  'crm.service.read',
  'crm.contract.read',
  'crm.price_book.read',
  'crm.quote.read'
)
WHERE r.code = 'OPERATIONS_MANAGER'
ON CONFLICT DO NOTHING;

-- Finance sees commercial/billing context but does not implicitly control sales approvals.
INSERT INTO role_permissions(role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
  'crm.counterparty.read',
  'crm.counterparty.preferences.manage',
  'crm.contact.read',
  'crm.contract.read',
  'crm.price_book.read',
  'crm.quote.read'
)
WHERE r.code IN ('FINANCE_MANAGER','ACCOUNTANT')
ON CONFLICT DO NOTHING;

-- Client users intentionally receive no internal crm.* permission here.
