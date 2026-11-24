-- 00_setup/supabase_seed_companies.sql
-- Seed: top 25 CFPB companies by complaint volume (bronze, 2025-11-23 → 2026-11-22)
-- company_name must match CFPB 'company' exactly. Types validated against complaint product mix (11/23).

create table if not exists public.companies (
  company_id      serial primary key,
  company_name    text not null unique,
  parent_company  text not null,
  company_type    text not null,
  hq_state        char(2),
  updated_at      timestamptz not null default now()
);

insert into public.companies (company_name, parent_company, company_type, hq_state) values
  ('TRANSUNION INTERMEDIATE HOLDINGS, INC.', 'TransUnion',                'Credit bureau',             'IL'),
  ('Experian Information Solutions Inc.',    'Experian plc',              'Credit bureau',             'CA'),
  ('EQUIFAX, INC.',                          'Equifax Inc.',              'Credit bureau',             'GA'),
  ('LEXISNEXIS',                             'RELX',                      'Consumer reporting agency', 'GA'),
  ('CAPITAL ONE FINANCIAL CORPORATION',      'Capital One',               'Bank',                      'VA'),
  ('CL Holdings LLC',                        'Jefferson Capital',         'Debt collector',            'MN'),
  ('JPMORGAN CHASE & CO.',                   'JPMorgan Chase',            'Bank',                      'NY'),
  ('BANK OF AMERICA, NATIONAL ASSOCIATION',  'Bank of America',           'Bank',                      'NC'),
  ('CITIBANK, N.A.',                         'Citigroup',                 'Bank',                      'NY'),
  ('Resurgent Capital Services L.P.',        'Sherman Financial Group',   'Debt collector',            'SC'),
  ('ENCORE CAPITAL GROUP INC.',              'Encore Capital Group',      'Debt collector',            'CA'),
  ('WELLS FARGO & COMPANY',                  'Wells Fargo',               'Bank',                      'CA'),
  ('CBC Companies, Inc.',                    'CBC Companies',             'Consumer reporting agency', 'OH'),
  ('Portfolio Recovery Associates, LLC',     'PRA Group',                 'Debt collector',            'VA'),
  ('SYNCHRONY FINANCIAL',                    'Synchrony',                 'Card issuer',               'CT'),
  ('Block, Inc.',                            'Block',                     'Fintech',                   'CA'),
  ('Paypal Holdings, Inc',                   'PayPal',                    'Fintech',                   'CA'),
  ('Chime Financial Inc',                    'Chime',                     'Fintech',                   'CA'),
  ('AMERICAN EXPRESS COMPANY',               'American Express',          'Card issuer',               'NY'),
  ('NAVY FEDERAL CREDIT UNION',              'Navy Federal Credit Union', 'Credit union',              'VA'),
  ('Bread Financial Holdings, Inc.',         'Bread Financial',           'Card issuer',               'OH'),
  ('CCS Financial Services, Inc.',           'CCS Financial Services',    'Debt collector',            'MA'),
  ('MOHELA',                                 'MOHELA',                    'Student loan servicer',     'MO'),
  ('Kriya Capital, LLC',                     'Kriya Capital',             'Debt collector',            'TX'),
  ('Affirm Holdings, Inc',                   'Affirm',                    'Fintech',                   'CA')
on conflict (company_name) do nothing;

select count(*) from public.companies;   -- expect 25