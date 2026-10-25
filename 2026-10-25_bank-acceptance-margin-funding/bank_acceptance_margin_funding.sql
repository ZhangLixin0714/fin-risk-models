
/* ======================================================================
   Model: Potential Funding of Bank Acceptance Margins from Corporate Loans
   Date: 2026-10-25
   Dialect: PostgreSQL reference implementation

   Purpose: Identify same-borrower loan disbursements preceding a bank
   acceptance margin deposit within a configurable observation window.

   IMPORTANT: This is a temporal association screen, NOT evidence that
   loan proceeds funded the margin. Verify account transaction trails.
   ====================================================================== */

WITH params AS (
    SELECT
        CAST(:START_DATE AS date) AS start_date,
        CAST(:END_DATE AS date) AS end_date,
        CAST(:LOOKBACK_DAYS AS integer) AS lookback_days
),

/* 1. Active bank acceptance margin records in the period. */
margin_deposits AS (
    SELECT
        m.margin_org_id,
        m.deposit_date::date AS margin_deposit_date,
        m.customer_id,
        m.margin_id,
        m.margin_account_id,
        m.margin_account_name,
        m.acceptance_type,
        m.accounting_code AS margin_accounting_code,
        m.currency_code AS margin_currency,
        m.amount_minor_units / 100.0 AS margin_amount,
        m.margin_status,
        m.settlement_account_id,
        m.margin_funding_account_id,
        m.related_host_reference,
        m.deposit_term,
        m.margin_maturity_date,
        m.deposit_operator_id
    FROM acceptance_margin_history m
    CROSS JOIN params p
    WHERE m.record_valid_from::date BETWEEN p.start_date AND p.end_date
      AND m.record_valid_to::date > p.start_date
      AND m.deposit_date::date BETWEEN p.start_date AND p.end_date
      AND m.acceptance_type IN ('BANK_ACCEPTANCE', 'E_BANK_ACCEPTANCE')
      AND m.margin_status = 'ACTIVE'
),

/* 2. Loan records in the reporting-date snapshot. */
loan_disbursements AS (
    SELECT
        l.org_id,
        l.customer_id,
        l.customer_name,
        l.contract_id,
        l.loan_note_id,
        l.loan_account_id,
        l.disbursement_date::date AS loan_disbursement_date,
        l.maturity_date::date AS loan_maturity_date,
        l.original_loan_amount,
        l.currency_code AS loan_currency,
        l.accounting_code AS loan_accounting_code,
        l.host_loan_note_id,
        l.host_loan_note_sequence,
        l.interest_payment_account_id,
        l.loan_type
    FROM corporate_loan_snapshot l
    CROSS JOIN params p
    WHERE l.snapshot_date::date = p.end_date
      AND l.disbursement_date::date BETWEEN p.start_date AND p.end_date
),

/* 3. Institution labels valid on the reporting date. */
current_org AS (
    SELECT
        o.org_id,
        o.region_name,
        o.branch_name,
        o.subbranch_name,
        o.outlet_name
    FROM organization_hierarchy o
    CROSS JOIN params p
    WHERE o.snapshot_date::date = p.end_date
      AND o.valid_from::date <= p.end_date
      AND o.valid_to::date > p.end_date
      AND o.org_type = 'BRANCH'
),

/* 4. Same borrower + loan preceding margin deposit. */
possible_matches AS (
    SELECT
        l.*,
        m.margin_org_id,
        m.margin_deposit_date,
        m.margin_id,
        m.margin_account_id,
        m.margin_account_name,
        m.acceptance_type,
        m.margin_accounting_code,
        m.margin_currency,
        m.margin_amount,
        m.margin_status,
        m.settlement_account_id,
        m.margin_funding_account_id,
        m.related_host_reference,
        m.deposit_term,
        m.margin_maturity_date,
        m.deposit_operator_id,
        (m.margin_deposit_date - l.loan_disbursement_date)
            AS days_between_disbursement_and_margin
    FROM margin_deposits m
    INNER JOIN loan_disbursements l
        ON l.customer_id = m.customer_id
    CROSS JOIN params p
    WHERE (m.margin_deposit_date - l.loan_disbursement_date)
          BETWEEN 0 AND p.lookback_days
)

SELECT DISTINCT
    o.region_name AS region,
    o.branch_name AS branch,
    o.subbranch_name AS subbranch,
    o.outlet_name AS outlet,
    x.org_id AS loan_org_id,
    x.customer_id,
    x.customer_name,
    x.contract_id,
    x.loan_note_id,
    x.loan_account_id,
    x.loan_disbursement_date,
    x.loan_maturity_date,
    x.original_loan_amount,
    x.loan_currency,
    x.loan_accounting_code,
    x.host_loan_note_id,
    x.host_loan_note_sequence,
    x.interest_payment_account_id,
    x.loan_type,
    x.margin_org_id,
    x.margin_deposit_date,
    x.margin_id,
    x.margin_account_id,
    x.margin_account_name,
    x.acceptance_type,
    x.margin_accounting_code,
    x.margin_currency,
    x.margin_amount,
    x.margin_status,
    x.settlement_account_id,
    x.margin_funding_account_id,
    x.related_host_reference,
    x.deposit_term,
    x.margin_maturity_date,
    x.deposit_operator_id,
    x.days_between_disbursement_and_margin,
    'TEMPORAL_ASSOCIATION_REQUIRES_FUNDS_FLOW_REVIEW' AS review_flag
FROM possible_matches x
LEFT JOIN current_org o
    ON o.org_id = x.org_id
ORDER BY
    branch, subbranch, customer_id, contract_id,
    loan_disbursement_date, margin_account_id, margin_deposit_date;
