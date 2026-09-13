/* ==============================================================
   Credit Operations Alerts — Overdue Investigation Response Monitoring

   Date: 2026-09-13

   Purpose:
   Identify SME credit-monitoring cases where the elapsed handling
   time exceeds the required investigation / feedback period.
   ============================================================== */

WITH params AS (
    SELECT
        CAST(:OBS_START_DATE AS DATE) AS obs_start_date,
        CAST(:REPORT_DATE AS DATE) AS report_date,
        CAST(:MAX_TOTAL_CONTRACT_AMT AS NUMERIC(18,2))
            AS max_total_contract_amt
),

/* --------------------------------------------------------------
   1. Eligible SME borrowers with active credit exposure
   -------------------------------------------------------------- */
eligible_sme AS (
    SELECT
        lc.customer_id,
        cm.customer_name,
        SUM(lc.contract_amount) AS total_contract_amount
    FROM corporate_loan_contract_summary lc

    INNER JOIN corporate_customer_master cm
        ON cm.customer_id = lc.customer_id
       AND cm.sme_flag = 'Y'

    CROSS JOIN params p

    WHERE lc.snapshot_date = p.report_date
      AND lc.loan_balance <> 0

    GROUP BY
        lc.customer_id,
        cm.customer_name

    HAVING SUM(lc.contract_amount)
           <= MAX(p.max_total_contract_amt)
),

/* --------------------------------------------------------------
   2. Customer / organization combinations with active loans
   -------------------------------------------------------------- */
active_exposure AS (
    SELECT DISTINCT
        es.customer_id,
        es.customer_name,
        la.org_id
    FROM eligible_sme es

    INNER JOIN corporate_loan_accounts la
        ON la.customer_id = es.customer_id

    CROSS JOIN params p

    WHERE la.snapshot_date = p.report_date
      AND la.principal_balance <> 0
),

/* --------------------------------------------------------------
   3. Current organization hierarchy
   -------------------------------------------------------------- */
current_org AS (
    SELECT
        oh.org_id,
        oh.level1_branch_name,
        oh.subbranch_name,
        oh.outlet_name
    FROM org_hierarchy oh
    CROSS JOIN params p

    WHERE oh.valid_to > p.report_date
),

/* --------------------------------------------------------------
   4. Monitoring alerts from source A
   -------------------------------------------------------------- */
monitoring_source_a AS (
    SELECT
        a.customer_id,
        a.alert_id,
        a.event_date,
        a.last_modified_date,
        a.required_response_days,
        a.investigation_required,

        (
            CAST(a.last_modified_date AS DATE)
            - CAST(a.event_date AS DATE)
        ) AS actual_response_days,

        'MONITORING_ALERT'
            AS alert_source

    FROM credit_monitoring_alert_history a

    CROSS JOIN params p

    WHERE a.event_date
          BETWEEN p.obs_start_date AND p.report_date

      AND (
          CAST(a.last_modified_date AS DATE)
          - CAST(a.event_date AS DATE)
      ) > a.required_response_days

      AND a.valid_to > p.report_date
),

/* --------------------------------------------------------------
   5. Monitoring / investigation records from source B
   -------------------------------------------------------------- */
monitoring_source_b AS (
    SELECT
        c.customer_id,
        c.alert_id,
        c.event_date,
        c.last_modified_date,
        c.required_response_days,
        c.investigation_required,

        (
            CAST(c.last_modified_date AS DATE)
            - CAST(c.event_date AS DATE)
        ) AS actual_response_days,

        'MONITORING_CASE'
            AS alert_source

    FROM credit_monitoring_case_history c

    CROSS JOIN params p

    WHERE c.event_date
          BETWEEN p.obs_start_date AND p.report_date

      AND (
          CAST(c.last_modified_date AS DATE)
          - CAST(c.event_date AS DATE)
      ) > c.required_response_days

      AND c.valid_to > p.report_date
),

/* --------------------------------------------------------------
   6. Combine monitoring sources
   -------------------------------------------------------------- */
overdue_events AS (

    SELECT * FROM monitoring_source_a

    UNION ALL

    SELECT * FROM monitoring_source_b
)

/* --------------------------------------------------------------
   7. Final exception population
   -------------------------------------------------------------- */
SELECT
    org.level1_branch_name AS level1_branch,
    org.subbranch_name     AS subbranch,
    org.outlet_name,

    ae.customer_id,
    ae.customer_name,

    oe.alert_id,
    oe.event_date,
    oe.last_modified_date,

    oe.required_response_days,
    oe.actual_response_days,

    (
        oe.actual_response_days
        - oe.required_response_days
    ) AS overdue_days,

    CASE
        WHEN oe.investigation_required = '1'
            THEN 'Yes'
        WHEN oe.investigation_required = '0'
            THEN 'No'
        ELSE 'Unknown'
    END AS investigation_required,

    oe.alert_source,

    'Overdue Investigation Response'
        AS timeliness_flag

FROM active_exposure ae

INNER JOIN overdue_events oe
    ON oe.customer_id = ae.customer_id

LEFT JOIN current_org org
    ON org.org_id = ae.org_id

ORDER BY
    overdue_days DESC,
    oe.event_date,
    ae.customer_id;
