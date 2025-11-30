/* ==============================================================
   E-Collateral Quick Loan — NPL Classification Extraction
   Date: 2025-11-30
   ============================================================== */

WITH params AS (
  SELECT
    CAST(:REPORT_DATE AS DATE)            AS report_date,
    CAST(:OBS_START_DATE AS DATE)         AS obs_start_date,
    CAST(:DPD_MIN AS INT)                 AS dpd_min,
    NULLIF(:INCLUDE_WRITEOFF,'')          AS include_writeoff_flag
),

-- 1. Core E-Collateral loans
core AS (
  SELECT
      l.loan_id,
      l.customer_id,
      l.product_category,
      l.classification,
      l.classification_date,
      l.origination_date,
      l.current_balance,
      l.days_past_due,
      l.writeoff_flag,
      l.org_id
  FROM loans l
  CROSS JOIN params p
  WHERE UPPER(l.product_category) = 'ECOLLATERAL_QUICK_LOAN'
    AND l.classification_date >= COALESCE(p.obs_start_date, DATE '1900-01-01')
    AND l.classification IN ('Substandard','Doubtful','Loss')
    AND (l.days_past_due >= p.dpd_min OR p.dpd_min IS NULL)
    AND (p.include_writeoff_flag = 'Y' OR l.writeoff_flag = 'N')
),

-- 2. Collateral join
coll AS (
  SELECT
      c.loan_id,
      c.collateral_type,
      c.collateral_value,
      ROW_NUMBER() OVER (PARTITION BY c.loan_id ORDER BY c.update_date DESC) AS rn
  FROM collateral c
),

-- 3. Customer info
cust AS (
  SELECT
      p.customer_id,
      p.customer_name,
      p.id_number
  FROM party p
),

-- 4. Org hierarchy
org_latest AS (
  SELECT oh.*,
         ROW_NUMBER() OVER(PARTITION BY oh.org_id ORDER BY oh.valid_to DESC, oh.valid_from DESC) AS rn
  FROM org_hierarchy oh
)

SELECT
    ol.level1_name AS level1_branch,
    ol.level2_name AS level2_branch,
    ol.level3_name AS level3_branch,

    c.loan_id,
    cu.customer_id,
    cu.customer_name,
    cu.id_number,

    c.classification,
    c.classification_date,
    c.days_past_due,
    c.current_balance,

    co.collateral_type,
    co.collateral_value,

    c.writeoff_flag,

    CASE
      WHEN c.classification = 'Loss' THEN 'High'
      WHEN c.classification = 'Doubtful' THEN 'Medium'
      ELSE 'Low'
    END AS severity
FROM core c
LEFT JOIN cust cu ON cu.customer_id = c.customer_id
LEFT JOIN coll co ON co.loan_id = c.loan_id AND co.rn = 1
LEFT JOIN org_latest ol ON ol.org_id = c.org_id AND ol.rn = 1
ORDER BY severity DESC, c.current_balance DESC, c.days_past_due DESC;
