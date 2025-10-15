/* ============================================================
   Corporate Loans Used to Redeem Same-Company Maturing Trade Bills
   Date: 2025-10-15   Author: <your-github-handle>
   ------------------------------------------------------------
   Parameters:
     :REPORT_DATE       (DATE)   snapshot/as-of date
     :OBS_START_DATE    (DATE)   lower bound for new loans
     :WINDOW_DAYS       (INT)    days before maturity (e.g., 3 or 7)
     :AMOUNT_TOL_PCT    (DECIMAL) fraction, e.g., 0.02 for 2%
     :CURRENCY          (TEXT)   optional, e.g., 'CNY'
   ------------------------------------------------------------ */

WITH params AS (
  SELECT
    CAST(:REPORT_DATE AS DATE)    AS report_date,
    CAST(:OBS_START_DATE AS DATE) AS obs_start_date,
    CAST(:WINDOW_DAYS AS INT)     AS window_days,
    CAST(:AMOUNT_TOL_PCT AS DECIMAL(9,6)) AS amount_tol_pct,
    NULLIF(TRIM(:CURRENCY),'')    AS currency_filter
),

-- 1) Eligible corporate loans
corp_loans AS (
  SELECT
      l.loan_id,
      l.party_id,
      l.product_code,
      l.product_category,
      l.start_interest_date,
      l.open_date,
      ABS(l.original_principal)      AS loan_amount,
      l.currency_code,
      l.org_id
  FROM loans l
  CROSS JOIN params p
  WHERE UPPER(l.product_category) = 'CORP_LOAN'
    AND l.start_interest_date >= COALESCE(p.obs_start_date, DATE '1900-01-01')
    AND (p.currency_filter IS NULL OR l.currency_code = p.currency_filter)
),

-- 2) Candidate trade bills
bills AS (
  SELECT
      tb.bill_id,
      tb.drawer_party_id,
      ABS(tb.bill_amount)         AS bill_amount,
      tb.bill_maturity_date,
      tb.drawer_open_bank_id
  FROM trade_bills tb
),

-- 3) Standard labels
org_latest AS (
  SELECT oh.*,
         ROW_NUMBER() OVER (PARTITION BY oh.org_id ORDER BY oh.valid_to DESC, oh.valid_from DESC) rn
  FROM org_hierarchy oh
),
prod_latest AS (
  SELECT pc.*,
         ROW_NUMBER() OVER (PARTITION BY pc.product_code ORDER BY pc.valid_to DESC, pc.valid_from DESC) rn
  FROM product_catalog pc
),
party_name AS (
  SELECT p.party_id, p.party_name FROM party p
)

-- 4) Match loans to bills of the same company within the pre-maturity window
SELECT
  ol.level1_name AS level1_branch,
  ol.level2_name AS level2_branch,
  ol.level3_name AS level3_branch,

  pn.party_name            AS company_name,
  c.party_id,
  c.loan_id,
  c.product_code,
  pl.product_name,
  c.currency_code,

  c.start_interest_date,
  c.open_date,
  b.bill_maturity_date,
  c.loan_amount,
  b.bill_amount,

  (c.loan_amount - b.bill_amount)                       AS amount_diff,
  CASE
     WHEN GREATEST(c.loan_amount, b.bill_amount) = 0 THEN 0
     ELSE ABS(c.loan_amount - b.bill_amount)
          / GREATEST(c.loan_amount, b.bill_amount)
  END                                                   AS amount_diff_pct,
  CASE
     WHEN c.start_interest_date BETWEEN (b.bill_maturity_date - (SELECT window_days FROM params) * INTERVAL '1 day')
                                    AND  b.bill_maturity_date
      AND ABS(c.loan_amount - b.bill_amount)
            / NULLIF(GREATEST(c.loan_amount, b.bill_amount),0)
            <= (SELECT amount_tol_pct FROM params)
     THEN 1 ELSE 0
  END                                                   AS window_match_flag,

  b.drawer_open_bank_id
FROM corp_loans c
JOIN bills b
  ON b.drawer_party_id = c.party_id
JOIN party_name pn
  ON pn.party_id = c.party_id
LEFT JOIN org_latest ol
  ON ol.org_id = c.org_id AND ol.rn = 1
LEFT JOIN prod_latest pl
  ON pl.product_code = c.product_code AND pl.rn = 1
WHERE c.start_interest_date BETWEEN (b.bill_maturity_date - (SELECT window_days FROM params) * INTERVAL '1 day')
                                AND  b.bill_maturity_date
  AND (
        CASE
          WHEN GREATEST(c.loan_amount, b.bill_amount) = 0 THEN 0
          ELSE ABS(c.loan_amount - b.bill_amount)
               / GREATEST(c.loan_amount, b.bill_amount)
        END
      ) <= (SELECT amount_tol_pct FROM params)
ORDER BY level1_branch, level2_branch, level3_branch, company_name, b.bill_maturity_date, c.start_interest_date, c.loan_id;
