-- =====================================================================
-- Çetele - Ön Muhasebe Uygulaması Veritabanı Şeması
-- Supabase SQL Editor'da çalıştırılmak üzere hazırlanmıştır.
-- Tüm parasal tutarlar NUMERIC(15,2) olarak saklanır.
-- Her tabloda kullanıcı bazlı Row Level Security (RLS) aktiftir.
-- =====================================================================

create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------------------
-- profiles: her Supabase auth kullanıcısına karşılık gelen profil bilgisi
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  company_name text,
  tax_number text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "profiles_delete_own"
  on public.profiles for delete
  using (auth.uid() = id);

-- Yeni kullanıcı kaydolduğunda otomatik profil oluşturur.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name');
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------------------------------------------------------------------
-- contacts: müşteri / tedarikçi cari kartları
-- ---------------------------------------------------------------------
create table if not exists public.contacts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  type text not null default 'customer' check (type in ('customer', 'supplier', 'both')),
  tax_number text,
  tax_office text,
  email text,
  phone text,
  address text,
  balance numeric(15, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists contacts_user_id_idx on public.contacts (user_id);

alter table public.contacts enable row level security;

create policy "contacts_select_own"
  on public.contacts for select
  using (auth.uid() = user_id);

create policy "contacts_insert_own"
  on public.contacts for insert
  with check (auth.uid() = user_id);

create policy "contacts_update_own"
  on public.contacts for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "contacts_delete_own"
  on public.contacts for delete
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- invoices: gelir / gider faturaları (KDV ve tevkifat dahil)
-- ---------------------------------------------------------------------
create table if not exists public.invoices (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users (id) on delete cascade,
  contact_id uuid references public.contacts (id) on delete set null,
  invoice_number text not null,
  type text not null check (type in ('sales', 'purchase')),
  status text not null default 'draft' check (status in ('draft', 'approved', 'paid', 'cancelled')),
  issue_date date not null default current_date,
  due_date date,
  subtotal numeric(15, 2) not null default 0,
  vat_rate numeric(5, 2) not null default 20,
  vat_amount numeric(15, 2) not null default 0,
  withholding_rate numeric(5, 2) not null default 0,
  withholding_amount numeric(15, 2) not null default 0,
  total_amount numeric(15, 2) not null default 0,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists invoices_user_id_idx on public.invoices (user_id);
create index if not exists invoices_contact_id_idx on public.invoices (contact_id);

alter table public.invoices enable row level security;

create policy "invoices_select_own"
  on public.invoices for select
  using (auth.uid() = user_id);

create policy "invoices_insert_own"
  on public.invoices for insert
  with check (auth.uid() = user_id);

create policy "invoices_update_own"
  on public.invoices for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "invoices_delete_own"
  on public.invoices for delete
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- invoice_items: fatura satır kalemleri
-- ---------------------------------------------------------------------
create table if not exists public.invoice_items (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users (id) on delete cascade,
  invoice_id uuid not null references public.invoices (id) on delete cascade,
  description text not null,
  quantity numeric(15, 2) not null default 1,
  unit_price numeric(15, 2) not null default 0,
  vat_rate numeric(5, 2) not null default 20,
  line_total numeric(15, 2) not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists invoice_items_invoice_id_idx on public.invoice_items (invoice_id);
create index if not exists invoice_items_user_id_idx on public.invoice_items (user_id);

alter table public.invoice_items enable row level security;

create policy "invoice_items_select_own"
  on public.invoice_items for select
  using (auth.uid() = user_id);

create policy "invoice_items_insert_own"
  on public.invoice_items for insert
  with check (auth.uid() = user_id);

create policy "invoice_items_update_own"
  on public.invoice_items for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "invoice_items_delete_own"
  on public.invoice_items for delete
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- transactions: kasa / banka para hareketleri
-- ---------------------------------------------------------------------
create table if not exists public.transactions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users (id) on delete cascade,
  contact_id uuid references public.contacts (id) on delete set null,
  invoice_id uuid references public.invoices (id) on delete set null,
  account_type text not null default 'cash' check (account_type in ('cash', 'bank')),
  direction text not null check (direction in ('in', 'out')),
  amount numeric(15, 2) not null check (amount >= 0),
  transaction_date date not null default current_date,
  description text,
  created_at timestamptz not null default now()
);

create index if not exists transactions_user_id_idx on public.transactions (user_id);
create index if not exists transactions_contact_id_idx on public.transactions (contact_id);
create index if not exists transactions_invoice_id_idx on public.transactions (invoice_id);

alter table public.transactions enable row level security;

create policy "transactions_select_own"
  on public.transactions for select
  using (auth.uid() = user_id);

create policy "transactions_insert_own"
  on public.transactions for insert
  with check (auth.uid() = user_id);

create policy "transactions_update_own"
  on public.transactions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "transactions_delete_own"
  on public.transactions for delete
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- updated_at kolonlarını otomatik güncelleyen ortak trigger
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_updated_at on public.profiles;
create trigger set_updated_at before update on public.profiles
  for each row execute procedure public.set_updated_at();

drop trigger if exists set_updated_at on public.contacts;
create trigger set_updated_at before update on public.contacts
  for each row execute procedure public.set_updated_at();

drop trigger if exists set_updated_at on public.invoices;
create trigger set_updated_at before update on public.invoices
  for each row execute procedure public.set_updated_at();
