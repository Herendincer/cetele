-- =====================================================================
-- Çetele - Ön Muhasebe Uygulaması Veritabanı Şeması
-- Supabase SQL Editor'da çalıştırılmak üzere hazırlanmıştır.
-- Mevcut parasal tutarlar NUMERIC(15,2); accounts.opening_balance BIGINT olarak saklanır.
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
  updated_at timestamptz not null default now(),
  constraint contacts_user_id_id_key unique (user_id, id)
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
-- accounts: kasa / banka hesapları
-- ---------------------------------------------------------------------
create table public.accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  type text not null check (type in ('cash', 'bank')),
  opening_balance bigint not null default 0,
  created_at timestamptz not null default now(),
  constraint accounts_user_id_id_key unique (user_id, id)
);

alter table public.accounts enable row level security;

create policy "accounts_select_own"
  on public.accounts for select
  using (auth.uid() = user_id);

create policy "accounts_insert_own"
  on public.accounts for insert
  with check (auth.uid() = user_id);

create policy "accounts_update_own"
  on public.accounts for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "accounts_delete_own"
  on public.accounts for delete
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- invoices: gelir / gider faturaları (KDV ve tevkifat dahil)
-- ---------------------------------------------------------------------
create table if not exists public.invoices (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users (id) on delete cascade,
  contact_id uuid,
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
  updated_at timestamptz not null default now(),
  constraint invoices_user_id_id_key unique (user_id, id),
  constraint invoices_user_id_invoice_number_key unique (user_id, invoice_number),
  constraint invoices_contact_id_fkey
    foreign key (user_id, contact_id) references public.contacts (user_id, id)
    on delete set null (contact_id)
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
  invoice_id uuid not null,
  description text not null,
  quantity numeric(15, 2) not null default 1,
  unit_price numeric(15, 2) not null default 0,
  vat_rate numeric(5, 2) not null default 20,
  discount_percent numeric default 0 check (discount_percent between 0 and 100),
  line_total numeric(15, 2) not null default 0,
  created_at timestamptz not null default now(),
  constraint invoice_items_invoice_id_fkey
    foreign key (user_id, invoice_id) references public.invoices (user_id, id)
    on delete cascade
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
  contact_id uuid,
  invoice_id uuid,
  account_id uuid references public.accounts (id),
  account_type text not null default 'cash' check (account_type in ('cash', 'bank')),
  direction text not null check (direction in ('in', 'out')),
  amount numeric(15, 2) not null check (amount >= 0),
  transaction_date date not null default current_date,
  description text,
  created_at timestamptz not null default now(),
  constraint transactions_contact_id_fkey
    foreign key (user_id, contact_id) references public.contacts (user_id, id)
    on delete set null (contact_id),
  constraint transactions_invoice_id_fkey
    foreign key (user_id, invoice_id) references public.invoices (user_id, id)
    on delete set null (invoice_id),
  constraint transactions_user_account_fkey
    foreign key (user_id, account_id) references public.accounts (user_id, id)
);

create index transactions_user_id_account_id_idx on public.transactions (user_id, account_id);
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

-- RPC, fatura ve tüm satırlarını çağıran işlemin tek transaction'ında yazar.
-- İstemci user_id/id/created_at gönderemez; JSON içindeki bu alanlar kullanılmaz.
-- Hata yakalanıp yutulmaz: geçersiz bir kalem faturayı da geri alır.
create or replace function public.create_invoice_with_items(
  p_invoice_number text,
  p_type text,
  p_items jsonb,
  p_contact_id uuid default null,
  p_status text default 'draft',
  p_issue_date date default current_date,
  p_due_date date default null,
  p_subtotal numeric default 0,
  p_vat_rate numeric default 20,
  p_vat_amount numeric default 0,
  p_withholding_rate numeric default 0,
  p_withholding_amount numeric default 0,
  p_total_amount numeric default 0,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_invoice_id uuid;
begin
  if v_user_id is null then
    raise exception 'Fatura oluşturmak için oturum açmalısınız.' using errcode = '42501';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    raise exception 'Fatura kalemleri bir JSON dizisi olmalıdır.' using errcode = '22023';
  end if;
  if jsonb_array_length(p_items) = 0 then
    raise exception 'Faturada en az bir kalem bulunmalıdır.' using errcode = '22023';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_items) as items(item)
    where jsonb_typeof(item) <> 'object'
  ) then
    raise exception 'Her fatura kalemi bir JSON nesnesi olmalıdır.' using errcode = '22023';
  end if;

  insert into public.invoices (
    user_id, contact_id, invoice_number, type, status, issue_date, due_date,
    subtotal, vat_rate, vat_amount, withholding_rate, withholding_amount,
    total_amount, notes
  ) values (
    v_user_id, p_contact_id, p_invoice_number, p_type, p_status, p_issue_date,
    p_due_date, p_subtotal, p_vat_rate, p_vat_amount, p_withholding_rate,
    p_withholding_amount, p_total_amount, p_notes
  ) returning id into v_invoice_id;

  insert into public.invoice_items (
    user_id, invoice_id, description, quantity, unit_price, vat_rate, discount_percent, line_total
  )
  select v_user_id, v_invoice_id, item ->> 'description',
    case when item ? 'quantity' then (item ->> 'quantity')::numeric else 1 end,
    case when item ? 'unit_price' then (item ->> 'unit_price')::numeric else 0 end,
    case when item ? 'vat_rate' then (item ->> 'vat_rate')::numeric else 20 end,
    coalesce((item ->> 'discount_percent')::numeric, 0),
    round(
      (case when item ? 'quantity' then (item ->> 'quantity')::numeric(15, 2) else 1 end)
      * (case when item ? 'unit_price' then (item ->> 'unit_price')::numeric(15, 2) else 0 end)
      * (1 - coalesce((item ->> 'discount_percent')::numeric, 0) / 100)
      * (1 + (case when item ? 'vat_rate' then (item ->> 'vat_rate')::numeric(5, 2) else 20 end) / 100),
      2
    )
  from jsonb_array_elements(p_items) as items(item);

  return v_invoice_id;
end;
$$;

revoke all on function public.create_invoice_with_items(
  text, text, jsonb, uuid, text, date, date, numeric, numeric, numeric,
  numeric, numeric, numeric, text
) from public, anon, authenticated;
grant execute on function public.create_invoice_with_items(
  text, text, jsonb, uuid, text, date, date, numeric, numeric, numeric,
  numeric, numeric, numeric, text
) to authenticated;

-- Pozitif bakiye alacağımızı, negatif bakiye borcumuzu gösterir (mevcut UI/ekstre).
-- Kesinleşmiş/gönderilmiş faturanın mevcut durum karşılığı approved veya paid.
-- Cari bakiye: onaylı/ödenmiş satış (+), alış (-), tahsilat (-), ödeme (+).
-- Taslak/iptal faturalar ve contact_id'si olmayan hareketler etkisizdir.
-- "paid" ayrıca ödeme yaratmaz; tahsilat/ödeme transactions'a kaydedilir.
-- INSERT yeni etkiyi ekler; DELETE eski etkiyi çıkarır; UPDATE eski etkiyi
-- geri alıp yenisini uygular (tutar, yön, tür, durum ve cari değişimleri dahil).
-- Trigger, mevcut contacts.balance okuyucularını korur; view gerektirmez.
-- Kilitli satıra atomik fark eklemek eşzamanlı yazmalarda kayıp güncellemeyi
-- önler. İki cari arasında taşımada kilitler id sırasıyla alınır.
create or replace function public.update_contact_balance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old_contact_id uuid;
  v_old_user_id uuid;
  v_new_contact_id uuid;
  v_new_user_id uuid;
  v_old_effect numeric := 0;
  v_new_effect numeric := 0;
begin
  if tg_op <> 'INSERT' then
    v_old_contact_id := old.contact_id;
    v_old_user_id := old.user_id;
    if tg_table_name = 'invoices' then
      if old.status in ('approved', 'paid') then
        v_old_effect := case when old.type = 'sales'
          then old.total_amount else -old.total_amount end;
      end if;
    else
      v_old_effect := case when old.direction = 'in'
        then -old.amount else old.amount end;
    end if;
  end if;

  if tg_op <> 'DELETE' then
    v_new_contact_id := new.contact_id;
    v_new_user_id := new.user_id;
    if tg_table_name = 'invoices' then
      if new.status in ('approved', 'paid') then
        v_new_effect := case when new.type = 'sales'
          then new.total_amount else -new.total_amount end;
      end if;
    else
      v_new_effect := case when new.direction = 'in'
        then -new.amount else new.amount end;
    end if;
  end if;

  perform id from public.contacts
  where (user_id = v_old_user_id and id = v_old_contact_id)
     or (user_id = v_new_user_id and id = v_new_contact_id)
  order by id for no key update;

  update public.contacts
  set balance = balance
    - case when user_id = v_old_user_id and id = v_old_contact_id
        then v_old_effect else 0 end
    + case when user_id = v_new_user_id and id = v_new_contact_id
        then v_new_effect else 0 end
  where (user_id = v_old_user_id and id = v_old_contact_id)
     or (user_id = v_new_user_id and id = v_new_contact_id);

  return null;
end;
$$;

revoke all on function public.update_contact_balance() from public, anon, authenticated;

create trigger invoices_update_contact_balance
  after insert or update or delete on public.invoices
  for each row execute function public.update_contact_balance();

create trigger transactions_update_contact_balance
  after insert or update or delete on public.transactions
  for each row execute function public.update_contact_balance();

-- Türetilmiş bakiye istemciden değiştirilemez. Yalnızca yukarıdaki kaynak
-- tablo trigger'ının içinden gelen iç içe güncellemeye izin verilir.
create or replace function public.protect_contact_balance()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.balance is distinct from 0::numeric then
      raise exception 'Cari bakiyesi fatura ve para hareketlerinden hesaplanır.'
        using errcode = '23514';
    end if;
  elsif new.balance is distinct from old.balance and pg_trigger_depth() = 1 then
    raise exception 'Cari bakiyesi doğrudan değiştirilemez.' using errcode = '23514';
  end if;
  return new;
end;
$$;

revoke all on function public.protect_contact_balance() from public, anon, authenticated;

create trigger contacts_protect_balance
  before insert or update on public.contacts
  for each row execute function public.protect_contact_balance();

-- TRUNCATE satır trigger'larını ve RLS'yi çalıştırmaz; istemci kullanamaz.
revoke truncate on public.contacts, public.invoices, public.transactions
  from public, anon, authenticated;
