-- Phase 1 migration'ından sonra bir kez, SQL Editor'da manuel çalıştırılır.
-- Eski kalemler korunur; yeni kalemlerde iskonto sonrası KDV dahil toplam
-- sunucuda hesaplanır. JSON line_total alanına güvenilmez.
begin;

alter table public.invoice_items
  add column discount_percent numeric default 0
    check (discount_percent between 0 and 100);

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

commit;
