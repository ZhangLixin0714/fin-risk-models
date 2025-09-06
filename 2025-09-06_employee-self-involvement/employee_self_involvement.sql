/* ============================================================
 Model: Employee Self-Involvement in Own Loan Workflow
 Date:  2025-09-06
 Goal:  Flag events where an employee performs workflow actions
        on a loan where they are the borrower (conflict of interest)
============================================================ */

/* ----------------------------
   Parameters (edit as needed)
   ----------------------------
   :REPORT_DATE            -> snapshot/as-of date (YYYY-MM-DD)
   :OBS_START_DATE         -> observation window start (YYYY-MM-DD)
   :OBS_END_DATE           -> observation window end   (YYYY-MM-DD)
   :EXCLUDE_SERVICE_ACCOUNTS -> set to TRUE to drop svc/bot accounts
   :EXCLUDE_VIEW_ONLY        -> set to TRUE to drop view-only events
   :RISK_ACTIONS             -> optional comma list to restrict actions
                               e.g. 'APPROVAL,DISBURSEMENT,RESTRUCTURE_APPROVAL'
*/

WITH
params AS (
  SELECT
    /* ---- set defaults; override in your runner if supported ---- */
    DATE ':REPORT_DATE'              ::date  AS report_date,
    DATE ':OBS_START_DATE'           ::date  AS obs_start_date,
    DATE ':OBS_END_DATE'             ::date  AS obs_end_date,
    COALESCE(NULLIF(':EXCLUDE_SERVICE_ACCOUNTS',''), 'TRUE')::boolean AS exclude_service_accounts,
    COALESCE(NULLIF(':EXCLUDE_VIEW_ONLY',''), 'TRUE')::boolean        AS exclude_view_only,
    /* if empty string, no restriction; otherwise split into array */
    NULLIF(trim(':RISK_ACTIONS'),'')                                    AS risk_actions_csv
),
/* -------------------------------------------------------------
   Normalize org data (optional; adapt to your schema)
--------------------------------------------------------------*/
org AS (
  SELECT
    oh.unit_id            AS branch_id,
    oh.unit_name          AS branch_name,
    oh.parent_path        AS org_path              -- e.g. "Region > Area > Branch"
  FROM org_hierarchy oh
),
/* -------------------------------------------------------------
   Map staff_id -> their personal retail customer_id
   (1:1 ideally; if 1:many keep most-recent/active)
--------------------------------------------------------------*/
staff_map AS (
  SELECT
      scm.staff_id,
      scm.customer_id,
      sd.staff_no,
      sd.full_name      AS staff_name,
      sd.email          AS staff_email,
      sd.is_service_acct
  FROM staff_customer_map scm
  JOIN staff_directory sd
    ON sd.staff_id = scm.staff_id
),
/* -------------------------------------------------------------
   Windowed workflow events with optional filters
--------------------------------------------------------------*/
events_win AS (
  SELECT
      lwe.event_id,
      lwe.event_ts,
      lwe.event_type,
      COALESCE(lwe.event_action, lwe.event_type) AS action_name,
      lwe.loan_id,
      lwe.actor_staff_id,
      lwe.actor_role,
      lwe.channel,
      lwe.branch_id,
      /* mark view-only/read events if your schema provides it */
      COALESCE(lwe.is_view_only, FALSE) AS is_view_only
  FROM loan_workflow_events lwe
  JOIN params p ON TRUE
  WHERE lwe.event_ts >= p.obs_start_date
    AND lwe.event_ts <  p.obs_end_date + INTERVAL '1 day'
    /* optional action restriction */
    AND (
          p.risk_actions_csv IS NULL
          OR position(','||upper(lwe.event_type)||',' IN
                      ','||upper(p.risk_actions_csv)||',') > 0
        )
),
/* -------------------------------------------------------------
   Join loans + events + org + staff mapping; keep only
   events where actor is also the borrower on that loan
--------------------------------------------------------------*/
base AS (
  SELECT
      e.event_id,
      e.event_ts,
      e.event_type,
      e.action_name,
      e.actor_staff_id,
      sm.staff_no,
      sm.staff_name,
      sm.staff_email,
      sm.is_service_acct,
      e.actor_role,
      e.channel,
      e.branch_id,
      o.branch_name,
      o.org_path,
      l.loan_id,
      l.product_code,
      l.origination_date,
      l.current_balance,
      l.primary_borrower_customer_id,
      pc.product_name
  FROM events_win e
  JOIN loans l
    ON l.loan_id = e.loan_id
  LEFT JOIN product_catalog pc
    ON pc.product_code = l.product_code
  LEFT JOIN org o
    ON o.branch_id = e.branch_id
  /* actor -> customer mapping */
  JOIN staff_map sm
    ON sm.staff_id = e.actor_staff_id
   AND sm.customer_id = l.primary_borrower_customer_id
),
/* -------------------------------------------------------------
   Apply policy filters & score severity
--------------------------------------------------------------*/
filtered AS (
  SELECT
      b.*,
      CASE
        WHEN upper(b.event_type) IN ('APPROVAL','DISBURSEMENT','RESTRUCTURE_APPROVAL') THEN 'HIGH'
        WHEN upper(b.event_type) IN ('APPLICATION_SUBMIT','DOC_VERIFICATION','CREDIT_ASSESSMENT','LIMIT_SETTING') THEN 'MEDIUM'
        ELSE 'LOW'
      END AS severity,
      CASE
        WHEN upper(b.event_type) IN ('APPROVAL','DISBURSEMENT','RESTRUCTURE_APPROVAL') THEN 3
        WHEN upper(b.event_type) IN ('APPLICATION_SUBMIT','DOC_VERIFICATION','CREDIT_ASSESSMENT','LIMIT_SETTING') THEN 2
        ELSE 1
      END AS severity_rank
  FROM base b
  JOIN params p ON TRUE
  WHERE (NOT p.exclude_service_accounts) OR (COALESCE(b.is_service_acct,FALSE) = FALSE)
    AND (NOT p.exclude_view_only) OR (COALESCE(b.is_view_only,FALSE) = FALSE)
)
SELECT
    /* reporting keys */
    f.event_id,
    f.event_ts,
    f.severity,
    f.severity_rank,

    /* organization */
    f.branch_id,
    f.branch_name,
    f.org_path,

    /* staff (actor) */
    f.actor_staff_id,
    f.staff_no,
    f.staff_name,
    f.staff_email,
    f.actor_role,

    /* loan */
    f.loan_id,
    f.product_code,
    f.product_name,
    f.origination_date,
    f.current_balance,
    f.primary_borrower_customer_id,

    /* event */
    f.event_type,
    f.action_name,
    f.channel
FROM filtered f
ORDER BY f.severity_rank DESC, f.event_ts DESC;
