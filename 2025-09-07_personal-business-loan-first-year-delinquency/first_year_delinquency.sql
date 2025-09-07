-- Personal Business Loan — First-Year Delinquency After Origination

with params as (
  select
    cast(:REPORT_DATE as date)        as report_date,
    cast(:OBS_START_DATE as date)     as obs_start_date,
    cast(:DAYS_LIMIT as int)          as days_limit,
    cast(:DELQ_DPD_THRESHOLD as int)  as delq_dpd_threshold
),

cohort as (
  select
    l.loan_id,
    l.customer_id,
    l.product_id,
    l.product_code,
    l.product_category,
    l.origination_date,
    l.maturity_date,
    l.currency_code,
    abs(l.current_principal_balance) as current_principal_balance,
    l.servicing_org_id
  from loans l
  cross join params p
  where l.product_category = 'PERSONAL_BUSINESS'
    and l.origination_date between coalesce(p.obs_start_date, date '1900-01-01') and p.report_date
),

first_delinquency as (
  select
    e.loan_id,
    min(e.event_date) filter (
      where e.days_past_due >= (select delq_dpd_threshold from params)
         or e.risk_class in ('SpecialMention','Substandard','Doubtful','Loss')
    ) as first_delq_date
  from loan_status_events e
  join cohort c on c.loan_id = e.loan_id
  group by e.loan_id
),

org_latest as (
  select oh.org_id, oh.level1_name, oh.level2_name, oh.level3_name,
         row_number() over (partition by oh.org_id order by oh.valid_to desc, oh.valid_from desc) as rn
  from org_hierarchy oh
),

prod_latest as (
  select pc.product_id, pc.product_name, pc.product_category,
         row_number() over (partition by pc.product_id order by pc.valid_to desc, pc.valid_from desc) as rn
  from product_catalog pc
)

select
  ol.level1_name  as level1_branch,
  ol.level2_name  as level2_branch,
  ol.level3_name  as level3_branch,
  c.customer_id,
  c.loan_id,
  c.product_code,
  c.product_id,
  pl.product_name,
  c.product_category,
  c.currency_code,
  c.origination_date,
  c.maturity_date,
  c.current_principal_balance,
  fd.first_delq_date,
  (fd.first_delq_date - c.origination_date) as days_to_first_delq,
  case
    when fd.first_delq_date is not null
         and fd.first_delq_date <= c.origination_date + (select days_limit from params) * interval '1 day'
      then 'First-Year Delinquency'
    else 'No First-Year Delinquency'
  end as first_year_delq_flag
from cohort c
left join first_delinquency fd on fd.loan_id = c.loan_id
left join org_latest ol on ol.org_id = c.servicing_org_id and ol.rn = 1
left join prod_latest pl on pl.product_id = c.product_id and pl.rn = 1
where fd.first_delq_date is not null
  and fd.first_delq_date <= c.origination_date + (select days_limit from params) * interval '1 day'
order by level1_branch, level2_branch, level3_branch, origination_date, first_delq_date, loan_id;
