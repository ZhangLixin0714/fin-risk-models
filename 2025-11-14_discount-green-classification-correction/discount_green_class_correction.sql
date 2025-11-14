/* ===============================================================
   Discount Financing — Artificial Green Classification (CRC)
   Date: 2025-11-14
   ============================================================== */

WITH params AS (
  SELECT
    CAST(:REPORT_DATE AS DATE)                  AS report_date,
    CAST(:OBS_START_DATE AS DATE)               AS obs_start_date,
    CAST(:GREEN_MISMATCH_THRESHOLD AS DECIMAL(6,4)) AS mismatch_threshold,
    CAST(:NONGREEN_FLOW_THRESHOLD AS DECIMAL(18,2)) AS nongreen_flow_threshold,
    NULLIF(:CRC_ONLY_FLAG, '')                  AS crc_only_flag
),

-- 1. Current green classification
green_registry AS (
  SELECT
      c.party_id,
      c.green_category,
      c.crc_flag
  FROM customer_green_class c
),

-- 2. Discount financing in window
discount_flows AS (
  SELECT
      d.party_id,
      d.bill_id,
      d.amount,
      d.use_of_proceeds,
      CASE WHEN LOWER(d.use_of_proceeds) LIKE '%green%' THEN 1 ELSE 0 END AS is_green_use
  FROM discount_bills d
  CROSS JOIN params p
  WHERE d.issue_date >= COALESCE(p.obs_start_date, DATE '1900-01-01')
),

-- 3. Loan flows in window
loan_flows AS (
  SELECT
      l.party_id,
      l.loan_id,
      l.amount,
      l.use_of_funds,
      CASE WHEN LOWER(l.use_of_funds) LIKE '%green%' THEN 1 ELSE 0 END AS is_green_use
  FROM loans l
  CROSS JOIN params p
  WHERE l.origination_date >= COALESCE(p.obs_start_date, DATE '1900-01-01')
),

-- 4. Combine discount + loan flows
combined_flows AS (
  SELECT
      party_id,
      SUM(amount)                              AS total_financing_amt,
      SUM(CASE WHEN is_green_use=0 THEN amount ELSE 0 END) AS non_green_flow_amt
  FROM (
        SELECT * FROM discount_flows
        UNION ALL
        SELECT * FROM loan_flows
       ) x
  GROUP BY party_id
),

-- 5. SME/Industry eligibility
industry_map AS (
  SELECT
      i.industry_code,
      CASE WHEN UPPER(i.green_eligible_flag)='Y' THEN 1 ELSE 0 END AS industry_green_eligible
  FROM industry_catalog i
),

-- 6. Join everything
joined AS (
  SELECT
      p.party_id,
      p.party_name,
      p.industry_code,
      im.industry_green_eligible,
      gr.green_category,
      gr.crc_flag,
      cf.total_financing_amt,
      cf.non_green_flow_amt,
      CASE 
        WHEN cf.total_financing_amt = 0 THEN 0
        ELSE cf.non_green_flow_amt / cf.total_financing_amt
      END AS mismatch_rate
  FROM party p
  LEFT JOIN industry_map im ON im.industry_code = p.industry_code
  LEFT JOIN green_registry gr ON gr.party_id = p.party_id
  LEFT JOIN combined_flows cf ON cf.party_id = p.party_id
)

SELECT
    j.*,
    CASE
      WHEN (crc_flag='Y') THEN 'CRC Client'
      WHEN (mismatch_rate > (SELECT mismatch_threshold FROM params)) THEN 'Green Mismatch'
      WHEN (non_green_flow_amt > (SELECT nongreen_flow_threshold FROM params)) THEN 'Large Non-Green Flow'
      ELSE 'Normal'
    END AS risk_label
FROM joined j
WHERE (:CRC_ONLY_FLAG IS NULL OR j.crc_flag = :CRC_ONLY_FLAG)
ORDER BY risk_label DESC, mismatch_rate DESC, total_financing_amt DESC;
