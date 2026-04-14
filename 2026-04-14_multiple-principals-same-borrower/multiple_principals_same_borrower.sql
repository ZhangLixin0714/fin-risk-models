/* ==============================================================
   Entrusted Loans — Multiple Different Principals Funding
   the Same Borrower
   Date: 2026-04-14
   ============================================================== */

WITH params AS (
  SELECT
    CAST(:REPORT_DATE AS DATE)            AS report_date,
    CAST(:OBS_START_DATE AS DATE)         AS obs_start_date,
    CAST(:MIN_PRINCIPAL_COUNT AS INT)     AS min_principal_count,
    CAST(:MIN_TOTAL_BALANCE AS NUMERIC(18,2)) AS min_total_balance,
    NULLIF(:INCLUDE_CLOSED, '')           AS include_closed
),

-- 1. Base entrusted loan population
base_loans AS (
  SELECT
      el.loan_id,
      el.borrower_id,
      el.principal_id,
      el.origination_date,
      el.current_balance,
      el.product_category,
      el.org_id,
      ls.loan_status,
      ls.risk_class
  FROM entrusted_loans el
  LEFT JOIN loan_status ls
    ON ls.loan_id = el.loan_id
  JOIN params p ON 1=1
  WHERE UPPER(el.product_category) = 'ENTRUSTED_LOAN'
    AND el.origination_date >= p.obs_start_date
    AND (
         p.include_closed IS NULL
         OR p.include_closed = 'Y'
         OR COALESCE(ls.loan_status, 'ACTIVE') <> 'CLOSED'
        )
),

-- 2. Borrower-level aggregation
borrower_agg AS (
  SELECT
      borrower_id,
      COUNT(DISTINCT principal_id) AS distinct_principal_count,
      COUNT(DISTINCT loan_id)      AS entrusted_loan_count,
      SUM(current_balance)         AS total_balance,
      MIN(origination_date)        AS earliest_origination_date,
      MAX(origination_date)        AS latest_origination_date
  FROM base_loans
  GROUP BY borrower_id
),

-- 3. Principal list per borrower
principal_list AS (
  SELECT
      borrower_id,
      STRING_AGG(CAST(principal_id AS TEXT), ', ' ORDER BY principal_id) AS principal_list
  FROM (
      SELECT DISTINCT borrower_id, principal_id
      FROM base_loans
  ) t
  GROUP BY borrower_id
),

-- 4. Borrower-org anchor
borrower_org AS (
  SELECT
      borrower_id,
      MIN(org_id) AS org_id
  FROM base_loans
  GROUP BY borrower_id
),

-- 5. Latest org labels
org_latest AS (
  SELECT
      oh.*,
      ROW_NUMBER() OVER (
        PARTITION BY oh.org_id
        ORDER BY oh.valid_to DESC, oh.valid_from DESC
      ) AS rn
  FROM org_hierarchy oh
)

SELECT
    ol.level1_name AS level1_branch,
    ol.level2_name AS level2_branch,
    ol.level3_name AS level3_branch,

    ba.borrower_id,
    pb.party_name AS borrower_name,

    ba.distinct_principal_count,
    pl.principal_list,
    ba.entrusted_loan_count,
    ba.total_balance,
    ba.earliest_origination_date,
    ba.latest_origination_date,

    'Multiple Principals to Same Borrower' AS warning_flag
FROM borrower_agg ba
LEFT JOIN principal_list pl
  ON pl.borrower_id = ba.borrower_id
LEFT JOIN borrower_org bo
  ON bo.borrower_id = ba.borrower_id
LEFT JOIN org_latest ol
  ON ol.org_id = bo.org_id
 AND ol.rn = 1
LEFT JOIN party pb
  ON pb.party_id = ba.borrower_id
JOIN params p ON 1=1
WHERE ba.distinct_principal_count >= p.min_principal_count
  AND ba.total_balance >= p.min_total_balance
ORDER BY
  ba.distinct_principal_count DESC,
  ba.total_balance DESC,
  ba.borrower_id;
