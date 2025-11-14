-- Personal Loan — Quarter-End Origination & Early Next-Quarter Payoff

WITH params AS (
  SELECT
    CAST(:REPORT_DATE AS date)        AS report_date,
    CAST(:OBS_START_DATE AS date)     AS obs_start_date,
    CAST(:ORIG_WINDOW_DAYS AS int)    AS orig_window_days,
    CAST(:PAYOFF_WINDOW_DAYS AS int)  AS payoff_window_days,
    CAST(:MAX_DAYS_TO_PAYOFF AS int)  AS max_days_to_payoff,
    CAST(:MIN_ORIG_AMT AS numeric(18,2)) AS min_orig_amt
),

cohort AS (
  SELECT
    l.loan_id,
    l.customer_id,
    l.product_id,
    l.product_category,
    l.origination_date,
    COALESCE(l.close_date, DATE NULL) AS close_date,
    l.currency_code,
    ABS(l.original_principal)         AS original_principal,
    ABS(l.current_principal_balance)  AS current_principal_balance,
    l.servicing_org_id
  FROM loans l
  CROSS JOIN params p
  WHERE l.product_category IN ('PERSONAL_LOAN','CONSUMER_LOAN')
    AND l.origination_date BETWEEN COALESCE(p.obs_start_date, DATE '1900-01-01') AND p.report_date
    AND ABS(l.original_principal) >= p.min_orig_amt
),

q_bounds AS (
  SELECT
    c.*,
    DATE_TRUNC('quarter', c.origination_date)::date                         AS q_start,
    (DATE_TRUNC('quarter', c.origination_date) + INTERVAL '3 months')::date AS next_q_start,
    ((DATE_TRUNC('quarter', c.origination_date) + INTERVAL '3 months')
       - INTERVAL '1 day')::date                                           AS q_end
  FROM cohort c
),

flagged AS (
  SELECT
    w.*,
    w.close_date                            AS payoff_date,
    (w.close_date - w.origination_date)     AS days_to_payoff
  FROM q_bounds w
  JOIN params p ON 1=1
  WHERE w.origination_date BETWEEN (w.q_end - (p.orig_window_days - 1) * INTERVAL '1 day') AND w.q_end
    AND w.close_date      BETWEEN  w.next_q_start AND (w.next_q_start + (p.payoff_window_days - 1) * INTERVAL '1 day')
    AND w.close_date IS NOT NULL
    AND (w.close_date - w.origination_date) BETWEEN 1 AND p.max_days_to_payoff
)

SELECT
  ol.level1_name  AS level1_branch,
  ol.level2_name  AS level2_branch,
  ol.level3_name  AS level3_branch,
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
FROM flagged f
LEFT JOIN (
  SELECT oh.*, ROW_NUMBER() OVER (PARTITION BY oh.org_id ORDER BY oh.valid_to DESC, oh.valid_from DESC) rn
  FROM org_hierarchy oh
) ol ON ol.org_id = f.servicing_org_id AND ol.rn = 1
LEFT JOIN (
  SELECT pc.*, ROW_NUMBER() OVER (PARTITION BY pc.product_id ORDER BY pc.valid_to DESC, pc.valid_from DESC) rn
  FROM product_catalog pc
) pc ON pc.product_id = f.product_id AND pc.rn = 1
ORDER BY
  level1_branch,
  level2_branch,
  level3_branch,
  f.origination_date,
  f.payoff_date,
  f.loan_id;
