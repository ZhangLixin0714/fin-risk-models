/* ==============================================================
   Corporate Loans — Interest Collection Configuration Anomaly Review
   Date: 2026-08-30

   Purpose:
   Build a review population of corporate loans with selected
   interest-period configurations and expose key fields needed
   to validate interest collection, pricing and delinquency.

   IMPORTANT:
   This query identifies records for review. It does not by itself
   calculate whether the amount of interest collected was incorrect.
   ============================================================== */

WITH params AS (
    SELECT
        CAST(:OBS_START_DATE AS DATE) AS obs_start_date,
        CAST(:SNAPSHOT_DATE AS DATE)  AS snapshot_date,
        CAST(:LOAN_ACCOUNT_TYPE AS VARCHAR(30)) AS loan_account_type,
        CAST(:AGREEMENT_PREFIX AS VARCHAR(20))  AS agreement_prefix
),

/* --------------------------------------------------------------
   1. Target loan-account agreements
   -------------------------------------------------------------- */
target_agreements AS (
    SELECT DISTINCT
        la.agreement_id,
        la.agreement_modifier,
        la.interest_period_code,
        ip.interest_period_description,
        la.start_date,
        la.end_date,
        la.start_interest_date,
        la.maturity_date,

        ap.party_id,
        related_customer.related_party_id AS related_customer_id,
        cm.customer_name

    FROM loan_account_history la

    LEFT JOIN agreement_party_relationships ap
        ON ap.agreement_id = la.agreement_id
       AND ap.relationship_type = :AGREEMENT_PARTY_RELATIONSHIP_TYPE
       AND ap.end_date = (SELECT snapshot_date FROM params)

    LEFT JOIN party_relationships relationship_level_1
        ON relationship_level_1.related_party_id = ap.party_id
       AND relationship_level_1.relationship_type =
           :PARTY_RELATIONSHIP_TYPE_1
       AND relationship_level_1.end_date =
           (SELECT snapshot_date FROM params)

    LEFT JOIN party_relationships related_customer
        ON related_customer.party_id =
           relationship_level_1.party_id
       AND related_customer.relationship_type =
           :PARTY_RELATIONSHIP_TYPE_2
       AND related_customer.end_date =
           (SELECT snapshot_date FROM params)

    LEFT JOIN customer_master cm
        ON cm.customer_id =
           related_customer.related_party_id

    LEFT JOIN interest_period_reference ip
        ON ip.interest_period_code =
           la.interest_period_code

    CROSS JOIN params p

    WHERE la.interest_period_code IN (
              :INTEREST_PERIOD_CODE_1,
              :INTEREST_PERIOD_CODE_2
          )

      AND la.account_type = p.loan_account_type

      AND la.start_interest_date >= p.obs_start_date

      AND (
          p.agreement_prefix IS NULL
          OR la.agreement_id LIKE p.agreement_prefix || '%'
      )
),

/* --------------------------------------------------------------
   2. Corporate loan detail
   -------------------------------------------------------------- */
loan_detail AS (
    SELECT
        cl.org_id,

        ta.agreement_id,
        ta.agreement_modifier,
        ta.interest_period_code,
        ta.interest_period_description,
        ta.start_date,
        ta.end_date,
        ta.start_interest_date AS account_start_interest_date,
        ta.maturity_date       AS account_maturity_date,

        cl.related_contract_id,
        cl.related_agreement_modifier,
        cl.loan_note_id,

        cl.product_id,
        pc.product_name,
        cl.product_level3_code,
        cl.general_ledger_code,

        cl.customer_id,
        cust.customer_name,

        cl.currency_code,
        cl.loan_principal_balance,

        cl.open_date,
        cl.start_interest_date,
        cl.maturity_date,
        cl.repaid_date,
        cl.repricing_date,

        cl.agreement_status_code,

        cl.risk_class_12,
        cl.risk_class_5,

        cl.loan_purpose_code,
        cl.repayment_mode_code,
        cl.repayment_period_code,

        cl.interest_rate_change_mode_code,
        cl.interest_rate_code,
        cl.loan_interest_rate_spread,

        cl.cumulative_disbursement_amount,
        cl.cumulative_repayment_amount,

        cl.written_off_principal_amount,
        cl.written_off_on_balance_interest,
        cl.written_off_off_balance_interest,

        cl.normal_principal_balance,
        cl.overdue_principal_balance,
        cl.overdue_start_date,

        cl.overdue_interest_rate,
        cl.overdue_interest_rate_spread,

        cl.on_balance_overdue_interest,
        cl.off_balance_overdue_interest,

        cl.principal_overdue_periods,
        cl.interest_overdue_periods

    FROM target_agreements ta

    INNER JOIN corporate_loan_agreements cl
        ON cl.agreement_id = ta.agreement_id
       AND cl.agreement_modifier = ta.agreement_modifier

    CROSS JOIN params p

    LEFT JOIN corporate_customer_master cust
        ON cust.customer_id = cl.customer_id

    LEFT JOIN product_catalog pc
        ON pc.product_id = cl.product_id
       AND pc.valid_from <= p.obs_start_date
       AND pc.valid_to   >  p.snapshot_date

    WHERE cl.start_interest_date >= p.obs_start_date
      AND (
          p.agreement_prefix IS NULL
          OR cl.agreement_id LIKE p.agreement_prefix || '%'
      )
),

/* --------------------------------------------------------------
   3. Current organization hierarchy
   -------------------------------------------------------------- */
org_current AS (
    SELECT
        oh.org_id,
        oh.level1_name,
        oh.level2_name,
        oh.level3_name,
        oh.org_name
    FROM org_hierarchy oh
    CROSS JOIN params p
    WHERE oh.valid_from <= p.obs_start_date
      AND oh.valid_to   >  p.snapshot_date
)

/* --------------------------------------------------------------
   4. Final review population
   -------------------------------------------------------------- */
SELECT DISTINCT
    oc.level1_name AS level1_branch,
    oc.level2_name AS level2_branch,
    oc.level3_name AS branch_name,
    oc.org_name    AS organization_name,

    ld.org_id,

    ld.agreement_id,
    ld.agreement_modifier,

    ld.interest_period_description,
    ld.start_date AS agreement_start_date,
    ld.end_date   AS agreement_end_date,

    ld.account_start_interest_date,
    ld.account_maturity_date,

    ld.related_contract_id AS loan_contract_id,
    ld.related_agreement_modifier,
    ld.loan_note_id,

    ld.product_id,
    ld.product_name,
    ld.product_level3_code,
    ld.general_ledger_code,

    ld.customer_id,
    ld.customer_name,

    ld.currency_code,
    ld.loan_principal_balance,

    ld.open_date,
    ld.start_interest_date,
    ld.maturity_date,
    ld.repaid_date,
    ld.repricing_date,

    ld.agreement_status_code,

    ld.risk_class_12,
    ld.risk_class_5,

    ld.loan_purpose_code,
    ld.repayment_mode_code,
    ld.repayment_period_code,

    ld.interest_rate_change_mode_code,
    ld.interest_rate_code,
    ld.loan_interest_rate_spread,

    ld.cumulative_disbursement_amount,
    ld.cumulative_repayment_amount,

    ld.written_off_principal_amount,
    ld.written_off_on_balance_interest,
    ld.written_off_off_balance_interest,

    ld.normal_principal_balance,
    ld.overdue_principal_balance,
    ld.overdue_start_date,

    ld.overdue_interest_rate,
    ld.overdue_interest_rate_spread,

    ld.on_balance_overdue_interest,
    ld.off_balance_overdue_interest,

    ld.principal_overdue_periods,
    ld.interest_overdue_periods,

    'Interest Collection Configuration Review'
        AS review_flag

FROM loan_detail ld

INNER JOIN org_current oc
    ON oc.org_id = ld.org_id

ORDER BY
    oc.level1_name,
    oc.level2_name,
    oc.level3_name,
    ld.customer_id,
    ld.loan_note_id;
