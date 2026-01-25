/* ==============================================================
   SME Borrowers (Non-NPL) — External Fraud Event Detection
   Date: 2026-01-25
   ============================================================== */

WITH params AS (
  SELECT
    CAST(:REPORT_DATE AS DATE)        AS report_date,
    CAST(:OBS_START_DATE AS DATE)     AS obs_start_date,
    NULLIF(:EXCLUDE_NPL,'')           AS exclude_npl,
    CAST(:MIN_EVENT_SEVERITY AS INT)  AS min_event_severity
),

-- 1. Performing SME loans
performing_loans AS (
  SELECT
      l.loan_id,
      l.customer_id,
      l.current_balance,
      l.risk_class,
      l.org_id
  FROM loans l
  JOIN customers c ON c.customer_id = l.customer_id
  JOIN params p ON 1=1
  WHERE c.customer_type = 'SME'
    AND (
         p.exclude_npl IS NULL
         OR (p.exclude_npl = 'Y' AND l.risk_class NOT IN ('Substandard','Doubtful','Loss'))
        )
),

-- 2. External fraud / legal events
external_events AS (
  SELECT
      e.customer_id,
      e.event_type,
      e.event_date,
      e.event_severity
  FROM external_risk_events e
  JOIN params p ON 1=1
  WHERE e.event_date >= p.obs_start_date
    AND e.event_severity >= p.min_event_severity
),

-- 3. Join and flag
flagged AS (
  SELECT
      pl.loan_id,
      pl.customer_id,
      pl.current_balance,
      pl.risk_class,
      ee.event_type,
      ee.event_date,
      ee.event_severity,
      pl.org_id
  FROM performing_loans pl
  JOIN external_events ee
    ON ee.customer_id = pl.customer_id
)

SELECT
    ol.level1_name AS level1_branch,
    ol.level2_name AS level2_branch,
    ol.level3_name AS level3_branch,

    f.customer_id,
    p.customer_name,
    f.loan_id,
    f.current_balance,

    f.risk_class AS internal_risk_class,
    f.event_type AS external_event_type,
    f.event_date,
    f.event_severity,

    'External Risk Warning' AS warning_flag
FROM flagged f
LEFT JOIN party p ON p.customer_id = f.customer_id
LEFT JOIN (
  SELECT oh.*,
         ROW_NUMBER() OVER (PARTITION BY oh.org_id ORDER BY oh.valid_to DESC, oh.valid_from DESC) rn
  FROM org_hierarchy oh
) ol ON ol.org_id = f.org_id AND ol.rn = 1
ORDER BY
  f.event_severity DESC,
  f.current_balance DESC,
  f.event_date DESC;
