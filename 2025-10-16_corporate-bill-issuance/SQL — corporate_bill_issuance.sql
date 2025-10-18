/* ===============================================================
   Corporate Trade Bill Issuance — Full Portfolio Monitoring
   Date: 2025-10-16
   =============================================================== */

WITH params AS (
  SELECT
    CAST(:REPORT_DATE AS DATE)       AS report_date,
    CAST(:OBS_START_DATE AS DATE)    AS obs_start_date,
    CAST(:RATIO_LIMIT AS DECIMAL(6,4)) AS ratio_limit,
    CAST(:GROUP_CONCENTRATION_LIMIT AS DECIMAL(6,4)) AS group_concentration_limit
),

-- 1) All trade bills issued in the observation window
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

-- 2) Aggregate by company
bill_summary AS (
  SELECT
      b.drawer_party_id,
      COUNT(DISTINCT b.bill_id)           AS issued_bill_count,
      SUM(b.bill_amount)                 AS total_bill_amount,
      AVG(b.tenor_days)                  AS avg_tenor_days
  FROM bills b
  GROUP BY b.drawer_party_id
),

-- 3) Combine with loan balance
loan_summary AS (
  SELECT
      l.party_id,
      SUM(l.current_balance) AS total_loan_balance
  FROM loans l
  WHERE UPPER(l.product_category) LIKE 'CORP%'
  GROUP BY l.party_id
),

-- 4) Join company attributes and calculate ratio
joined AS (
  SELECT
      p.party_id,
      p.party_name,
      p.industry_code,
      p.region_code,
      COALESCE(bs.issued_bill_count,0)    AS issued_bill_count,
      COALESCE(bs.total_bill_amount,0)    AS total_bill_amount,
      COALESCE(bs.avg_tenor_days,0)       AS avg_tenor_days,
      COALESCE(ls.total_loan_balance,0)   AS total_loan_balance,
      CASE WHEN COALESCE(ls.total_loan_balance,0)=0 THEN NULL
           ELSE bs.total_bill_amount / ls.total_loan_balance END AS bill_to_loan_ratio
  FROM party p
  LEFT JOIN bill_summary bs ON p.party_id = bs.drawer_party_id
  LEFT JOIN loan_summary ls ON p.party_id = ls.party_id
),

-- 5) Branch enrichment
org_latest AS (
  SELECT oh.*, ROW_NUMBER() OVER(PARTITION BY oh.org_id ORDER BY oh.valid_to DESC, oh.valid_from DESC) rn
  FROM org_hierarchy oh
),

final AS (
  SELECT
      jl.party_id,
      jl.party_name,
      jl.industry_code,
      jl.region_code,
      jl.issued_bill_count,
      jl.total_bill_amount,
      jl.avg_tenor_days,
      jl.total_loan_balance,
      jl.bill_to_loan_ratio,
      ol.level1_name,
      ol.level2_name,
      ol.level3_name,
      CASE
        WHEN jl.bill_to_loan_ratio > (SELECT ratio_limit FROM params) THEN 'High Ratio'
        ELSE 'Normal'
      END AS risk_flag
  FROM joined jl
  LEFT JOIN org_latest ol ON ol.org_id = jl.party_id AND ol.rn = 1  -- adjust if branch linkage stored elsewhere
)

SELECT *
FROM final
ORDER BY risk_flag DESC, total_bill_amount DESC, party_name;
