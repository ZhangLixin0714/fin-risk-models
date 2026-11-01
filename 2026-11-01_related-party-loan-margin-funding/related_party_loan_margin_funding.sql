
/* ====================================================================
   Model: Potential Funding of Bank Acceptance Margins from
          Related-Party Corporate Loans
   Date: 2026-11-01
   Dialect: PostgreSQL reference implementation

   Detection: A company deposits a bank acceptance margin shortly
   after a DIFFERENT company in the same credit group receives a loan.

   This is a temporal/group-relationship screen, not funds tracing.
   ==================================================================== */

WITH params AS (
    SELECT
        CAST(:START_DATE AS date) AS start_date,
        CAST(:END_DATE AS date) AS end_date,
        CAST(:LOOKBACK_DAYS AS integer) AS lookback_days
),

/* 1. Bank acceptance margin deposits in the observation period. */
margin_deposits AS (
    SELECT DISTINCT
        m.customer_id AS margin_customer_id,
        m.org_id AS margin_org_id,
        m.margin_id,
        m.margin_account_id,
        m.margin_account_name,
        CAST(m.deposit_date AS date) AS margin_deposit_date,
        m.margin_amount_minor_units / 100.0 AS margin_amount,
        m.acceptance_type,
        m.margin_status,
        m.settlement_account_id,
        m.margin_funding_account_id,
        m.host_reference_id
    FROM acceptance_margin_history m
    CROSS JOIN params p
    WHERE CAST(m.record_valid_from AS date)
              BETWEEN p.start_date AND p.end_date
      AND CAST(m.record_valid_to AS date) > p.start_date
      AND CAST(m.deposit_date AS date)
              BETWEEN p.start_date AND p.end_date
      AND m.acceptance_type IN
              ('BANK_ACCEPTANCE', 'E_BANK_ACCEPTANCE')
),

/* 2. Credit-group membership at the reporting snapshot. */
group_members AS (
    SELECT DISTINCT
        gm.group_id,
        gm.customer_id,
        cm.customer_name
    FROM credit_group_membership_snapshot gm
    CROSS JOIN params p
    INNER JOIN corporate_customer_master cm
        ON cm.customer_id = gm.customer_id
       AND cm.snapshot_date = p.end_date
    WHERE gm.snapshot_date = p.end_date
),

/* 3. Different companies belonging to the same credit group. */
related_company_pairs AS (
    SELECT DISTINCT
        a.group_id,
        a.customer_id AS margin_customer_id,
        a.customer_name AS margin_customer_name,
        b.customer_id AS related_borrower_id,
        b.customer_name AS related_borrower_name
    FROM group_members a
    INNER JOIN group_members b
        ON b.group_id = a.group_id
       AND b.customer_id <> a.customer_id
),

/* 4. Corporate loans disbursed during the observation period. */
corporate_loans AS (
    SELECT DISTINCT
        l.customer_id AS related_borrower_id,
        l.org_id AS loan_org_id,
        l.contract_id,
        l.loan_note_id,
        l.loan_account_id,
        CAST(l.disbursement_date AS date) AS loan_disbursement_date,
        CAST(l.maturity_date AS date) AS loan_maturity_date,
        l.original_loan_amount,
        l.currency_code AS loan_currency,
        l.accounting_code AS loan_accounting_code,
        l.host_loan_note_id,
        l.host_loan_note_sequence,
        l.interest_payment_account_id,
        l.loan_type
    FROM corporate_loan_snapshot l
    CROSS JOIN params p
    WHERE l.snapshot_date = p.end_date
      AND CAST(l.disbursement_date AS date)
              BETWEEN p.start_date AND p.end_date
),

/* 5. Match margin company A to group-related borrower B. */
possible_matches AS (
    SELECT
        rp.group_id,
        rp.margin_customer_id,
        rp.margin_customer_name,
        rp.related_borrower_id,
        rp.related_borrower_name,
        m.margin_org_id,
        m.margin_id,
        m.margin_account_id,
        m.margin_account_name,
        m.margin_deposit_date,
        m.margin_amount,
        m.acceptance_type,
        m.margin_status,
        m.settlement_account_id,
        m.margin_funding_account_id,
        m.host_reference_id,
        l.loan_org_id,
        l.contract_id,
        l.loan_note_id,
        l.loan_account_id,
        l.loan_disbursement_date,
        l.loan_maturity_date,
        l.original_loan_amount,
        l.loan_currency,
        l.loan_accounting_code,
        l.host_loan_note_id,
        l.host_loan_note_sequence,
        l.interest_payment_account_id,
        l.loan_type,
        (m.margin_deposit_date - l.loan_disbursement_date)
            AS days_between_disbursement_and_margin
    FROM margin_deposits m
    INNER JOIN related_company_pairs rp
        ON rp.margin_customer_id = m.margin_customer_id
    INNER JOIN corporate_loans l
        ON l.related_borrower_id = rp.related_borrower_id
    CROSS JOIN params p
    WHERE (m.margin_deposit_date - l.loan_disbursement_date)
              BETWEEN 0 AND p.lookback_days
),

/* 6. Margin institution hierarchy valid at the report date. */
current_org AS (
    SELECT DISTINCT
        o.org_id,
        o.region_name,
        o.branch_name,
        o.subbranch_name,
        o.outlet_name
    FROM organization_hierarchy o
    CROSS JOIN params p
    WHERE o.snapshot_date = p.end_date
      AND o.valid_from <= p.end_date
      AND o.valid_to > p.end_date
      AND o.org_type = 'BRANCH'
)

SELECT DISTINCT
    o.region_name AS region,
    o.branch_name AS branch,
    o.subbranch_name AS subbranch,
    o.outlet_name AS outlet,
    x.group_id,
    x.margin_customer_id,
    x.margin_customer_name,
    x.margin_org_id,
    x.margin_account_id,
    x.margin_id,
    x.margin_account_name,
    x.margin_deposit_date,
    x.margin_amount,
    x.acceptance_type,
    x.margin_status,
    x.settlement_account_id,
    x.margin_funding_account_id,
    x.host_reference_id,
    x.related_borrower_id,
    x.related_borrower_name,
    x.loan_org_id,
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
    x.days_between_disbursement_and_margin,
    'RELATED_PARTY_TEMPORAL_ASSOCIATION_REQUIRES_REVIEW'
        AS review_flag
FROM possible_matches x
LEFT JOIN current_org o
    ON o.org_id = x.margin_org_id
ORDER BY
    branch,
    subbranch,
    margin_customer_id,
    margin_account_id,
    margin_id,
    related_borrower_id,
    contract_id,
    loan_note_id;
