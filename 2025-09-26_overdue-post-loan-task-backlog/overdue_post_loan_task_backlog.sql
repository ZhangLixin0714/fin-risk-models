/* ===========================================================
   Personal Loans — Overdue Post-Loan Task Backlog
   Snapshot: :snapshot_date   Window: :lookback_days days
   Author: <your-handle>
   =========================================================== */

WITH
params AS (
  SELECT
    CAST(:snapshot_date AS DATE)          AS snapshot_date,
    CAST(:lookback_days AS INT)           AS lookback_days,
    CAST(:overdue_rate_threshold AS DECIMAL(5,4)) AS overdue_rate_threshold,
    CAST(:overdue_cnt_threshold  AS INT)  AS overdue_cnt_threshold,
    CAST(:min_persist_days       AS INT)  AS min_persist_days
),
-- 1) Personal-loan tasks in the lookback window
task_base AS (
  SELECT
    t.task_id,
    t.loan_id,
    COALESCE(t.branch_id, l.booked_branch_id) AS branch_id,
    COALESCE(t.officer_id, l.officer_id)      AS officer_id,
    t.task_type,
    t.due_date,
    t.completed_at,
    t.created_at
  FROM post_loan_task t
  JOIN loan l
    ON l.loan_id = t.loan_id
   AND UPPER(l.product) = 'PERSONAL'
  CROSS JOIN params p
  WHERE t.created_at < p.snapshot_date + INTERVAL '1' DAY
    AND t.created_at >= p.snapshot_date - (p.lookback_days || ' days')::INTERVAL
),
-- 2) Overdue status (at snapshot)
task_flags AS (
  SELECT
    b.*,
    CASE
      WHEN b.completed_at IS NULL AND b.due_date < (SELECT snapshot_date FROM params) THEN 1
      WHEN b.completed_at IS NOT NULL AND b.completed_at::date > b.due_date THEN 1
      ELSE 0
    END AS is_overdue
  FROM task_base b
),
-- 3) Daily aggregates to measure persistence
daily_rollup AS (
  SELECT
    p.snapshot_date - dd AS day,
    f.branch_id,
    f.officer_id,
    COUNT(*)                      AS task_cnt,
    SUM(f.is_overdue)             AS overdue_cnt
  FROM generate_series(
         0,
         (SELECT lookback_days FROM params)::INT - 1,
         1
       ) AS dd
  JOIN params p ON TRUE
  JOIN task_flags f
    ON f.created_at::date <= (p.snapshot_date - dd)
   AND (f.completed_at IS NULL OR f.completed_at::date > (p.snapshot_date - dd))
  GROUP BY 1,2,3
),
-- 4) Window-level aggregates
window_agg AS (
  SELECT
    d.branch_id,
    d.officer_id,
    SUM(d.task_cnt)                             AS task_cnt,
    SUM(d.overdue_cnt)                          AS overdue_cnt,
    CASE WHEN SUM(d.task_cnt) = 0 THEN 0
         ELSE SUM(d.overdue_cnt)::DECIMAL / SUM(d.task_cnt) END AS overdue_rate,
    -- persistence: days in window with any overdue backlog
    SUM(CASE WHEN d.overdue_cnt > 0 THEN 1 ELSE 0 END) AS persist_days
  FROM daily_rollup d
  GROUP BY d.branch_id, d.officer_id
),
-- 5) Add labels
decorated AS (
  SELECT
    p.snapshot_date,
    w.branch_id,
    COALESCE(b.branch_name, 'N/A')  AS branch_name,
    w.officer_id,
    COALESCE(o.officer_name, 'N/A') AS officer_name,
    w.task_cnt,
    w.overdue_cnt,
    w.overdue_rate,
    w.persist_days
  FROM window_agg w
  CROSS JOIN params p
  LEFT JOIN branch b  ON b.branch_id  = w.branch_id
  LEFT JOIN officer o ON o.officer_id = w.officer_id
)
SELECT *
FROM decorated d, params p
WHERE (d.overdue_rate >= p.overdue_rate_threshold OR d.overdue_cnt >= p.overdue_cnt_threshold)
  AND d.persist_days >= p.min_persist_days
ORDER BY d.overdue_rate DESC, d.overdue_cnt DESC, d.branch_name, d.officer_name;
