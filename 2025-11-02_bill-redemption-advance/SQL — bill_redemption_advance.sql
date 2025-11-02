/* ==============================================================
   Trade Bill Redemption — Advance Payment Detection
   Date: 2025-11-02
   ============================================================== */

WITH params AS (
  SELECT
    CAST(:REPORT_DATE AS DATE)           AS report_date,
    CAST(:OBS_START_DATE AS DATE)        AS obs_start_date,
    CAST(:ADVANCE_WINDOW_DAYS AS INT)    AS advance_window_days,
    CAST(:ADVANCE_RATIO_LIMIT AS DECIMAL(6,4)) AS advance_ratio_limit,
    CAST(:FREQUENCY_LIMIT AS INT)        AS frequency_limit
),

-- 1) Bills maturing in observation window
matured_bills AS (
  SELECT
      tb.bill_id,
      tb.drawer_party_id,
      tb.payee_party_id,
      tb.bill_maturity_date,
      ABS(tb.bill_amount) AS bill_amount,
      tb.redemption_date,
      tb.redemption_source_acct_id
  FROM trade_bills tb
  CROSS JOIN params p
  WHERE tb.bill_maturity_date BETWEEN p.obs_start_date AND p.report_date
),

-- 2) Identify redemption source ownership
source_map AS (
  SELECT
      a.acct_id,
      a.party_id AS source_party_id,
      p.party_name AS source_party_name,
      p.group_id  AS source_group_id
  FROM accounts a
  LEFT JOIN party p ON p.party_id = a.party_id
),

-- 3) Tag “advance” redemptions
flagged AS (
  SELECT
      mb.*,
      sm.source_party_id,
      sm.source_party_name,
      sm.source_group_id,
      CASE
        WHEN mb.redemption_source_acct_id IS NULL THEN 'Unknown'
        WHEN sm.source_party_id = mb.drawer_party_id THEN 'Self-Payment'
        WHEN mb.redemption_date < mb.bill_maturity_date
             AND mb.bill_maturity_date - mb.redemption_date <=
                 (SELECT advance_window_days FROM params)
          THEN 'Advance by Third Party'
        ELSE 'Normal'
      END AS redemption_type
  FROM matured_bills mb
  LEFT JOIN source_map sm
    ON sm.acct_id = mb.redemption_source_acct_id
),

-- 4) Aggregate by drawer
drawer_summary AS (
  SELECT
      f.drawer_party_id,
      COUNT(DISTINCT f.bill_id)                         AS bill_count,
      SUM(f.bill_amount)                                AS total_bill_amount,
      SUM(CASE WHEN f.redemption_type='Advance by Third Party'
               THEN f.bill_amount ELSE 0 END)           AS advance_amount,
      COUNT(CASE WHEN f.redemption_type='Advance by Third Party' THEN 1 END)
                                                     AS advance_events
  FROM flagged f
  GROUP BY f.drawer_party_id
),

-- 5) Combine and flag
final AS (
  SELECT
      ds.drawer_party_id,
      pt.party_name,
      pt.group_id,
      ds.bill_count,
      ds.total_bill_amount,
      ds.advance_amount,
      CASE WHEN ds.total_bill_amount=0 THEN 0
           ELSE ds.advance_amount/ds.total_bill_amount END AS advance_ratio,
      ds.advance_events,
      CASE
        WHEN ds.advance_amount/ds.total_bill_amount >
             (SELECT advance_ratio_limit FROM params)
          OR ds.advance_events >= (SELECT frequency_limit FROM params)
        THEN 'High Risk'
        ELSE 'Normal'
      END AS risk_flag
  FROM drawer_summary ds
  LEFT JOIN party pt ON pt.party_id = ds.drawer_party_id
)

SELECT *
FROM final
ORDER BY risk_flag DESC, advance_ratio DESC, bill_count DESC;
