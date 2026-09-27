-- Phase 4: yalnızca oturum sahibinin bu aya ait satış faturalarını sayar.
-- Elle uygulanmalıdır. Takvim ayı sunucu saatinden Europe/Istanbul'a göre bulunur.
-- Son ürün kararı gereği created_at değil issue_date kullanılır; silinen faturalar
-- ve başka aya taşınan faturalar bu ayın sayımından çıkar. Durum filtresi yoktur.
begin;

create index if not exists invoices_monthly_sales_count_idx
  on public.invoices (user_id, issue_date)
  where type = 'sales';

create or replace function public.count_monthly_sales_invoices()
returns bigint
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_month_start date := pg_catalog.date_trunc(
    'month', pg_catalog.now() at time zone 'Europe/Istanbul'
  )::date;
begin
  if v_user_id is null then
    raise exception 'Fatura kullanımını görmek için oturum açmalısınız.'
      using errcode = '42501';
  end if;

  return (
    select count(*)
    from public.invoices as invoice
    where invoice.user_id = v_user_id
      and invoice.type = 'sales'
      and invoice.issue_date >= v_month_start
      and invoice.issue_date < (v_month_start + interval '1 month')::date
  );
end;
$$;

-- Supabase misafir oturumları da authenticated rolündedir; oturumsuz anon değildir.
revoke all on function public.count_monthly_sales_invoices() from public, anon;
grant execute on function public.count_monthly_sales_invoices() to authenticated;

commit;
