-- Mortgage — Large Card Installment in the 90 Days Pre-Disbursement
with params as (
  select 
    cast(:REPORT_DATE as date)     as report_date,
    cast(:OBS_START_DATE as date)  as obs_start_date,
    cast(:LOOKBACK_DAYS as int)    as lookback_days,
    cast(:MIN_INSTALLMENT_AMT as numeric(18,2)) as min_installment_amt
),

-- 1) Eligible mortgage loans in the observation window
mortgage_loans as (
  select
    l.loan_id,
    l.customer_id,
    l.product_id,
    l.product_code,
    l.product_category,
    l.contract_id,
    l.currency_code,
    l.start_interest_date,
    l.current_principal_balance,
    l.host_org_id
  from loan_accounts l
  cross join params p
  where l.product_category = 'MORTGAGE'
    and l.start_interest_date between coalesce(p.obs_start_date, date '1900-01-01') and p.report_date
),

-- 2) Latest org names
org_latest as (
  select o.org_id,
         o.level1_name, o.level2_name, o.level3_name,
         row_number() over(partition by o.org_id order by o.valid_to desc, o.valid_from desc) as rn
  from org_hierarchy o
),

-- 3) Relevant credit-card installments in the pre-loan window (global filter by report_date & amount)
pre_window_installments as (
  select
    ci.customer_id,
    ci.installment_agreement_id,
    ci.effect_date,
    ci.installment_amount,
    ci.remaining_amount,
    ci.issuing_org_id
  from card_installments ci
  cross join params p
  where ci.effect_date <= p.report_date
    and ci.installment_amount >= p.min_installment_amt
),

-- 4) Join: for each loan, find installments within [start_interest_date - LOOKBACK_DAYS, start_interest_date]
flag_join as (
  select
    ol.level1_name  as level1_branch,
    ol.level2_name  as level2_branch,
    ol.level3_name  as level3_branch,

    ml.customer_id,
    ml.loan_id,
    ml.product_code,
    ml.product_id,
    pc.product_name,

    ml.contract_id,
    ml.currency_code,
    ml.start_interest_date,
    ld.disbursement_date,
    ld.disbursement_amount,

    abs(ml.current_principal_balance) as current_principal_balance,

    ci.effect_date     as installment_effect_date,
    ci.installment_amount,
    ci.remaining_amount,
    ci.installment_agreement_id,
    ci.issuing_org_id
  from mortgage_loans ml
  join params p on 1=1
  left join product_catalog pc
    on pc.product_id = ml.product_id
    and pc.product_category = 'MORTGAGE'
  left join org_latest ol
    on ol.org_id = ml.host_org_id and ol.rn = 1
  left join lateral (
      select d.*
      from loan_disbursements d
      where d.loan_id = ml.loan_id
  ) ld on true
  join pre_window_installments ci
    on ci.customer_id = ml.customer_id
   and ci.effect_date >= ml.start_interest_date - (p.lookback_days || ' days')::interval
   and ci.effect_date <= ml.start_interest_date
)
select *
from flag_join
order by level1_branch, level2_branch, level3_branch, customer_id, start_interest_date, installment_effect_date;

/* Dialect notes:
   - MySQL: effect_date >= DATE_SUB(ml.start_interest_date, INTERVAL p.lookback_days DAY)
   - SQL Server: effect_date >= DATEADD(DAY, -p.lookback_days, ml.start_interest_date)
   - Oracle: effect_date >= (ml.start_interest_date - p.lookback_days)
*/
