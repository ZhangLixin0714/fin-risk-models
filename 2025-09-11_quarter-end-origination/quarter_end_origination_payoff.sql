-- Personal Loan — Quarter-End Origination & Early Next-Quarter Payoff

with params as (
  select
    cast(:REPORT_DATE as date)        as report_date,
    cast(:OBS_START_DATE as date)     as obs_start_date,
    cast(:ORIG_WINDOW_DAYS as int)    as orig_window_days,
    cast(:PAYOFF_WINDOW_DAYS as int)  as payoff_window_days,
    cast(:MAX_DAYS_TO_PAYOFF as int)  as max_days_to_payoff,
    cast(:MIN_ORIG_AMT as numeric(18,2)) as min_orig_amt
),

cohort as (
  select
    l.loan_id,
    l.customer_id,
    l.product_id,
    l.product_category,
    l.origination_date,
    coalesce(l.close_date, date null) as close_date,
    l.currency_code,
    abs(l.original_principal) as original_principal,
    abs(l.current_principal_balance) as current_principal_balance,
    l.servicing_org_id
  from loans l
  cross join params p
  where l.product_category in ('PERSONAL_LOAN','CONSUMER_LOAN')
    and l.origination_date between coalesce(p.obs_start_date, date '1900-01-01') and p.report_date
    and abs(l.original_principal) >= p.min_orig_amt
),

with_q_bounds as (
  select
    c.*,
    date_trunc('quarter', c.origination_date)::date                         as q_start,
    (date_trunc('quarter', c.origination_date) + interval '3 months')::date as next_q_start,
    ((date_trunc('quarter', c.origination_date) + interval '3 months')
       - interval '1 day')::date                                            as q_end
  from cohort c
),

flagged as (
  select
    w.*,
    w.close_date                                           as payoff_date,
    (w.close_date - w.origination_date)                    as days_to_payoff
  from with_q_bounds w
  join params p on 1=1
  where w.origination_date between (w.q_end - (p.orig_window_days - 1) * interval '1 day') and w.q_end
    and w.close_date      between  w.next_q_start and (w.next_q_start + (p.payoff_window_days - 1) * interval '1 day')
    and w.close_date is not null
    and (w.close_date - w.origination_date) between 1 and p.max_days_to_payoff
)

select
  ol.level1_name  as level1_branch,
  ol.level2_name  as level2_branch,
  ol.level3_name  as level3_branch,
  f.customer_id,
  f.loan_id,
  f.product_id,
  pc.product_name,
  f.product_category,
  f.currency_code,
  f.original_principal,
  f.origination_date,
  f.payoff_date,
  f.days_to_payoff
from flagged f
left join (
  select oh.*, row_number() over(partition by oh.org_id order by oh.valid_to desc, oh.valid_from desc) rn
  from org_hierarchy oh
) ol on ol.org_id = f.servicing_org_id and ol.rn = 1
left join (
  select pc.*, row_number() over(partition by pc.product_id order by pc.valid_to desc, pc.valid_from desc) rn
  from product_catalog pc
) pc on pc.product_id = f.product_id and pc.rn = 1
order by level1_branch, level2_branch, level3_branch, f.origination_date, f.payoff_date, f.loan_id;
