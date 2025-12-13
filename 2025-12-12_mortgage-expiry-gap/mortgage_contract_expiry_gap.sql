/* ==============================================================
   Corporate Loan — Mortgage Contract Expiry Gap Detection
   Date: 2025-12-12
   ============================================================== */

WITH params AS (
  SELECT
    CAST(:REPORT_DATE AS DATE)      AS report_date,
    CAST(:OBS_START_DATE AS DATE)   AS obs_start_date,
    CAST(:MIN_GAP_DAYS AS INT)      AS min_gap_days,
    NULLIF(:INCLUDE_OVERDUE_ONLY,'') AS include_overdue_only
),

-- 1. Active corporate loans
loan_base AS (
  SELECT
      l.loan_id,
      l.customer_id,
      l.product_category,
      l.origination_date,
      l.maturity_date,
      l.current_balance,
      l.risk_class,
      l.days_past_due,
      l.org_id
  FROM loans l
  CROSS JOIN params p
  WHERE UPPER(l.product_category) = 'CORPORATE_LOAN'
    AND l.maturity_date >= p.obs_start_date
    AND (
          p.include_overdue_only IS NULL
          OR (p.include_overdue_only = 'Y' AND l.days_past_due > 0)
        )
),

-- 2. Mortgage contracts
mortgage AS (
  SELECT
      mc.loan_id,
      mc.contract_id,
      mc.expiry_date AS mortgage_expiry_date
  FROM mortgage_contracts mc
),

-- 3. Latest org labels
org_latest AS (
  SELECT oh.*,
         ROW_NUMBER() OVER (PARTITION BY oh.org_id ORDER BY oh.valid_to DESC, oh.valid_from DESC) rn
  FROM org_hierarchy oh
),

-- 4. Join and compute gap
joined AS (
  SELECT
      lb.loan_id,
      lb.customer_id,
      lb.maturity_date,
      m.mortgage_expiry_date,
      (lb.maturity_date - m.mortgage_expiry_date) AS gap_days,
      lb.current_balance,
      lb.risk_class,
      lb.days_past_due,
      lb.org_id
  FROM loan_base lb
  JOIN mortgage m ON m.loan_id = lb.loan_id
  WHERE m.mortgage_expiry_date < lb.maturity_date
)

SELECT
    ol.level1_name AS level1_branch,
    ol.level2_name AS level2_branch,
    ol.level3_name AS level3_branch,

    j.loan_id,
    j.customer_id,
    p.customer_name,

    j.maturity_date,
    j.mortgage_expiry_date,
    j.gap_days,

    j.current_balance,
    j.risk_class,

    CASE
      WHEN j.gap_days >= 180 THEN 'High'
      WHEN j.gap_days >= 90  THEN 'Medium'
      ELSE 'Low'
    END AS severity
FROM joined j
LEFT JOIN party p ON p.customer_id = j.customer_id
LEFT JOIN org_latest ol ON ol.org_id = j.org_id AND ol.rn = 1
WHERE j.gap_days >= (SELECT min_gap_days FROM params)
ORDER BY severity DESC, j.gap_days DESC, j.current_balance DESC;
