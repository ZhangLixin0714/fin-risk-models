/* ==============================================================
   SME Trade Bill Issuance Monitoring
   Date: 2025-10-17
   ============================================================== */

WITH params AS (
  SELECT
    CAST(:REPORT_DATE AS DATE)      AS report_date,
    CAST(:OBS_START_DATE AS DATE)   AS obs_start_date,
    CAST(:RATIO_LIMIT AS DECIMAL(6,4)) AS ratio_limit,
    CAST(:GROWTH_THRESHOLD AS DECIMAL(6,4)) AS growth_threshold,
    CAST(:AMOUNT_LIMIT AS NUMERIC(18,2)) AS amount_limit
),

-- 1. SME bills in observation window
bills AS (
  SELECT
      tb.bill_id,
      tb.drawer_party_id,
      tb.bill_issue_date,
      tb.bill_maturity_date,
      ABS(tb.bill_amount) AS bill_amount,
      tb.currency_code,
      tb.issuing_org_id,
      EXTRACT(DAY FROM (tb.bill_maturity_date - tb.bill_issue_date)) AS tenor_days
  FROM trade_bills tb
  CROSS JOIN params p
  WHERE tb.bill_issue_date BETWEEN p.obs_start_date AND p.report_date
),

-- 2. Aggregate by enterprise
bill_summary AS (
  SELECT
      b.drawer_party_id,
      COUNT(DISTINCT b.bill_id)       AS bill_count,
      SUM(b.bill_amount)              AS total_bill_amount,
      AVG(b.tenor_days)               AS avg_tenor_days
  FROM bills b
  GROUP BY b.drawer_party_id
),

-- 3. SME filter
sme_party AS (
  SELECT p.party_id, p.party_name, p.enterprise_scale
  FROM party p
  WHERE UPPER(p.enterprise_scale) IN ('SME','SMALL','MICRO','MINI')
),

-- 4. Loan exposure
loan_summary AS (
  SELECT
      l.party_id,
      SUM(l.current_balance) AS total_loan_balance
  FROM loans l
  WHERE UPPER(l.product_category) LIKE 'CORP%'
  GROUP BY l.party_id
),

-- 5. Join & compute ratios
joined AS (
  SELECT
      s.party_id,
      s.party_name,
      s.enterprise_scale,
      COALESCE(bs.bill_count,0)          AS bill_count,
      COALESCE(bs.total_bill_amount,0)   AS total_bill_amount,
      COALESCE(bs.avg_tenor_days,0)      AS avg_tenor_days,
      COALESCE(ls.total_loan_balance,0)  AS total_loan_balance,
      CASE WHEN COALESCE(ls.total_loan_balance,0)=0 THEN NULL
           ELSE bs.total_bill_amount / ls.total_loan_balance END AS bill_to_loan_ratio
  FROM sme_party s
  LEFT JOIN bill_summary bs ON s.party_id = bs.drawer_party_id
  LEFT JOIN loan_summary ls ON s.party_id = ls.party_id
),

-- 6. Risk flag
final AS (
  SELECT
      j.*,
      CASE
        WHEN j.total_bill_amount > (SELECT amount_limit FROM params) THEN 'Exceeds Amount Limit'
        WHEN j.bill_to_loan_ratio > (SELECT ratio_limit FROM params) THEN 'High Bill-to-Loan Ratio'
        ELSE 'Normal'
      END AS risk_flag
  FROM joined j
)

SELECT
    f.party_id,
    f.party_name,
    f.enterprise_scale,
    f.bill_count,
    f.total_bill_amount,
    f.avg_tenor_days,
    f.total_loan_balance,
    f.bill_to_loan_ratio,
    f.risk_flag
FROM final f
ORDER BY f.risk_flag DESC, f.total_bill_amount DESC, f.party_name;
