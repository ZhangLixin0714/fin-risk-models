/* ==============================================================
   SME Loans — Time to NPL (Seasoning Risk)
   Date: 2026-05-04
   ============================================================== */

WITH params AS (
  SELECT
    CAST(:REPORT_DATE AS DATE)        AS report_date,
    CAST(:EARLY_DEFAULT_DAYS AS INT)  AS early_default_days,
    CAST(:OBS_START_DATE AS DATE)     AS obs_start_date,
    NULLIF(:INCLUDE_ONLY_NPL,'')      AS include_only_npl
),

-- 1. SME loans
loan_base AS (
  SELECT
      l.loan_id,
      l.customer_id,
      l.origination_date,
      l.product_category,
      l.org_id
  FROM loans l
  JOIN customers c ON c.customer_id = l.customer_id
  JOIN params p ON 1=1
  WHERE c.enterprise_size IN ('SME','SMALL','MICRO')
    AND l.origination_date >= p.obs_start_date
),

-- 2. First NPL classification
npl_events AS (
  SELECT
      h.loan_id,
      MIN(h.classification_date) AS first_npl_date
  FROM loan_classification_history h
  WHERE h.classification IN ('Substandard','Doubtful','Loss')
  GROUP BY h.loan_id
),

-- 3. Join and calculate
joined AS (
  SELECT
      lb.loan_id,
      lb.customer_id,
      lb.origination_date,
      ne.first_npl_date,
      (ne.first_npl_date - lb.origination_date) AS days_to_npl,
      lb.org_id
  FROM loan_base lb
  LEFT JOIN npl_events ne ON ne.loan_id = lb.loan_id
),

-- 4. Flag early default
flagged AS (
  SELECT
      j.*,
      CASE
        WHEN j.first_npl_date IS NULL THEN 'Performing'
        WHEN j.days_to_npl <= (SELECT early_default_days FROM params)
          THEN 'Early Default'
        ELSE 'Normal Default'
      END AS early_default_flag
  FROM joined j
)

SELECT
    ol.level1_name AS level1_branch,
    ol.level2_name AS level2_branch,
    ol.level3_name AS level3_branch,

    f.loan_id,
    f.customer_id,
    p.customer_name,

    f.origination_date,
    f.first_npl_date,
    f.days_to_npl,
    f.early_default_flag
FROM flagged f
LEFT JOIN party p ON p.customer_id = f.customer_id
LEFT JOIN (
  SELECT oh.*, ROW_NUMBER() OVER (PARTITION BY org_id ORDER BY valid_to DESC) rn
  FROM org_hierarchy oh
) ol ON ol.org_id = f.org_id AND ol.rn = 1
ORDER BY
  f.early_default_flag DESC,
  f.days_to_npl ASC;
