/* ==============================================================
   Newly Originated Loans — Short-Term Credit Deterioration

   Date: 2026-09-06

   Purpose:
   Identify loans that become overdue or materially deteriorate
   within approximately one year after a new credit relationship
   or new loan origination.
   ============================================================== */

WITH params AS (
    SELECT
        CAST(:SNAPSHOT_DATE AS DATE) AS snapshot_date,
        CAST(:OBS_START_DATE AS DATE) AS observation_start_date,
        CAST(:LOOKBACK_START_DATE AS DATE) AS lookback_start_date,
        CAST(:EARLY_DETERIORATION_DAYS AS INTEGER)
            AS early_deterioration_days
),

/* ==============================================================
   Population 1:
   Existing loan population with short-term deterioration after
   establishment of a new credit relationship
   ============================================================== */

loan_population_1 AS (
    SELECT
        l.org_id,
        l.customer_id,
        l.customer_name,
        l.loan_contract_id,
        l.loan_id,

        l.loan_balance,
        l.currency_code,
        l.accounting_subject,

        l.original_loan_amount,
        l.origination_date,
        l.maturity_date,
        l.adjusted_maturity_date,

        l.loan_type,
        l.product_code,
        l.new_credit_relationship_time,
        l.five_grade_classification,

        first_overdue.first_overdue_date,

        first_relationship.new_credit_relationship_date,

        (
            first_overdue.first_overdue_date
            - first_relationship.new_credit_relationship_date
        ) AS days_to_deterioration,

        CAST(NULL AS NUMERIC(18,2)) AS overdue_principal

    FROM loan_master l

    INNER JOIN (
        SELECT
            contract_id,
            MIN(event_date) AS first_overdue_date
        FROM loan_event_history
        CROSS JOIN params p
        WHERE event_date <= p.snapshot_date
          AND event_type = 'OVERDUE'
        GROUP BY contract_id
    ) first_overdue
        ON first_overdue.contract_id = l.loan_contract_id

    INNER JOIN (
        SELECT
            customer_id,
            MIN(relationship_start_date)
                AS new_credit_relationship_date
        FROM customer_credit_relationship_history
        CROSS JOIN params p
        WHERE relationship_start_date <= p.snapshot_date
        GROUP BY customer_id
    ) first_relationship
        ON first_relationship.customer_id = l.customer_id

    CROSS JOIN params p

    WHERE l.snapshot_date = p.snapshot_date

      AND l.loan_balance <> 0

      AND l.origination_date >= p.observation_start_date

      AND first_overdue.first_overdue_date
          >= first_relationship.new_credit_relationship_date

      AND (
          first_overdue.first_overdue_date
          - first_relationship.new_credit_relationship_date
      ) <= p.early_deterioration_days
),

/* ==============================================================
   Population 2:
   Newly originated loans that become overdue and migrate into
   adverse five-grade classifications
   ============================================================== */

first_overdue_by_contract AS (
    SELECT
        loan_contract_id,
        MIN(overdue_date) AS first_overdue_date
    FROM loan_account_snapshot
    CROSS JOIN params p
    WHERE snapshot_date <= p.snapshot_date
      AND overdue_principal <> 0
      AND overdue_date >= origination_date
      AND overdue_date BETWEEN
          p.lookback_start_date AND p.snapshot_date
    GROUP BY loan_contract_id
),

first_new_loan_by_customer AS (
    SELECT
        customer_id,
        MIN(origination_date) AS new_loan_date
    FROM loan_account_snapshot
    CROSS JOIN params p
    WHERE snapshot_date BETWEEN
          p.lookback_start_date AND p.snapshot_date
    GROUP BY customer_id
),

loan_population_2 AS (
    SELECT
        l.org_id,
        l.customer_id,
        c.customer_name,

        l.loan_contract_id,
        l.loan_id,

        (l.normal_principal_balance + l.overdue_principal)
            AS loan_balance,

        l.currency_code,
        l.accounting_subject,

        l.original_loan_amount,
        l.origination_date,
        l.maturity_date,
        l.adjusted_maturity_date,

        CAST(NULL AS VARCHAR(50)) AS loan_type,
        l.product_code,

        CAST(NULL AS DATE) AS new_credit_relationship_time,

        l.five_grade_classification,

        fo.first_overdue_date,

        nl.new_loan_date AS new_credit_relationship_date,

        (
            fo.first_overdue_date
            - nl.new_loan_date
        ) AS days_to_deterioration,

        l.overdue_principal

    FROM loan_account_snapshot l

    INNER JOIN first_overdue_by_contract fo
        ON fo.loan_contract_id = l.loan_contract_id

    INNER JOIN first_new_loan_by_customer nl
        ON nl.customer_id = l.customer_id

    LEFT JOIN customer_master c
        ON c.customer_id = l.customer_id

    CROSS JOIN params p

    WHERE l.snapshot_date = p.snapshot_date

      AND l.five_grade_classification
          IN ('SUBSTANDARD', 'DOUBTFUL', 'LOSS')

      AND fo.first_overdue_date >= nl.new_loan_date

      AND (
          fo.first_overdue_date
          - nl.new_loan_date
      ) <= p.early_deterioration_days

      AND l.origination_date >= p.observation_start_date
),

/* ==============================================================
   Combine both populations
   ============================================================== */

combined_population AS (

    SELECT * FROM loan_population_1

    UNION ALL

    SELECT * FROM loan_population_2
)

/* ==============================================================
   Final output
   ============================================================== */

SELECT
    org.level1_name AS level1_branch,
    org.level2_name AS level2_branch,
    org.branch_name AS business_org,

    cp.customer_id,
    cp.customer_name,

    cp.loan_contract_id,
    cp.loan_id,

    cp.loan_balance,
    cp.currency_code,
    cp.accounting_subject,

    cp.original_loan_amount,
    cp.origination_date,
    cp.maturity_date,
    cp.adjusted_maturity_date,

    cp.first_overdue_date,
    cp.new_credit_relationship_date,

    cp.days_to_deterioration,

    cp.loan_type,
    cp.product_code,
    cp.new_credit_relationship_time,

    cp.five_grade_classification,
    cp.overdue_principal,

    CASE
        WHEN cp.days_to_deterioration <= 90
            THEN 'Very Early Deterioration'

        WHEN cp.days_to_deterioration <= 180
            THEN 'Early Deterioration'

        ELSE 'Short-Term Deterioration'
    END AS deterioration_flag

FROM combined_population cp

LEFT JOIN org_hierarchy org
    ON org.org_id = cp.org_id

ORDER BY
    cp.days_to_deterioration ASC,
    cp.overdue_principal DESC,
    cp.loan_balance DESC;
