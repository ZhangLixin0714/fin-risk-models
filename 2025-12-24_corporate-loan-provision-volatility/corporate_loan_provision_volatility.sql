/* ==============================================================
   Corporate Loan — Provision Volatility Detection
   Date: 2025-12-24
   ============================================================== */

WITH params AS (
  SELECT
    CAST(:REPORT_DATE AS DATE)              AS report_date,
    CAST(:PREV_DATE AS DATE)                AS prev_date,
    CAST(:ABS_CHANGE_THRESHOLD AS NUMERIC(18,2)) AS abs_change_threshold,
    CAST(:REL_CHANGE_THRESHOLD AS DECIMAL(6,4))  AS rel_change_threshold,
    CAST(:MIN_BALANCE AS NUMERIC(18,2))     AS min_balance,
    NULLIF(:INCLUDE_WRITE_OFF,'')           AS include_write_off
),

-- 1. Current provisions
prov_curr AS (
  SELECT
      lp.note_id,
      lp.provision_amount AS provision_curr
  FROM loan_provisions lp
  JOIN params p ON lp.provision_date = p.report_date
),

-- 2. Previous provisions
prov_prev AS (
  SELECT
      lp.note_id,
      lp.provision_amount AS provision_prev
  FROM loan_provisions lp
  JOIN params p ON lp.provision_date = p.prev_date
),

-- 3. Core loan notes
note_base AS (
  SELECT
      n.note_id,
      n.loan_id,
      n.customer_id,
      n.outstanding_balance,
      n.org_id
  FROM loan_notes n
  JOIN params p ON 1=1
  WHERE n.outstanding_balance >= p.min_balance
),

-- 4. Join everything
joined AS (
  SELECT
      nb.note_id,
      nb.loan_id,
      nb.customer_id,
      nb.outstanding_balance,
      pc.provision_curr,
      pp.provision_prev,
      (pc.provision_curr - pp.provision_prev) AS provision_change_amt,
      CASE
        WHEN pp.provision_prev = 0 THEN NULL
        ELSE (pc.provision_curr - pp.provision_prev) / pp.provision_prev
      END AS provision_change_pct,
      l.risk_class,
      l.days_past_due,
      l.restructuring_flag,
      l.writeoff_flag,
      nb.org_id
  FROM note_base nb
  LEFT JOIN prov_curr pc ON pc.note_id = nb.note_id
  LEFT JOIN prov_prev pp ON pp.note_id = nb.note_id
  LEFT JOIN loans l ON l.loan_id = nb.loan_id
),

-- 5. Apply rules
flagged AS (
  SELECT
      j.*,
      CASE
        WHEN ABS(j.provision_change_amt) >= (SELECT abs_change_threshold FROM params)
          THEN 'Absolute Change'
        WHEN ABS(j.provision_change_pct) >= (SELECT rel_change_threshold FROM params)
          THEN 'Relative Change'
        ELSE 'Normal'
      END AS risk_flag
  FROM joined j
  JOIN params p ON 1=1
  WHERE (p.include_write_off = 'Y' OR j.writeoff_flag = 'N')
)

SELECT
    ol.level1_name AS level1_branch,
    ol.level2_name AS level2_branch,
    ol.level3_name AS level3_branch,

    f.note_id,
    f.loan_id,
    p.customer_name,
    f.outstanding_balance,

    f.provision_prev,
    f.provision_curr,
    f.provision_change_amt,
    f.provision_change_pct,

    f.risk_class,
    f.days_past_due,
    f.risk_flag
FROM flagged f
LEFT JOIN party p ON p.customer_id = f.customer_id
LEFT JOIN (
  SELECT oh.*, ROW_NUMBER() OVER (PARTITION BY oh.org_id ORDER BY oh.valid_to DESC, oh.valid_from DESC) rn
  FROM org_hierarchy oh
) ol ON ol.org_id = f.org_id AND ol.rn = 1
ORDER BY
  risk_flag DESC,
  ABS(provision_change_amt) DESC,
  outstanding_balance DESC;
