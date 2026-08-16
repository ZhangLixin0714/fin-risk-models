/* ==============================================================
   SME Operating Cash Flows Primarily Sourced
   from Related Enterprises

   Date: 2026-08-15

   Purpose:
   Identify SME borrowers for which related enterprises account
   for a significant proportion of operating cash inflows during
   the 180 days preceding loan disbursement.
   ============================================================== */

WITH params AS (
    SELECT
        CAST(:LOOKBACK_DAYS AS INTEGER) AS lookback_days,
        CAST(:RELATED_PARTY_RATIO_THRESHOLD AS DECIMAL(8,4))
            AS related_party_ratio_threshold,
        CAST(:SNAPSHOT_DATE AS DATE) AS snapshot_date
),

/* 1. SME loan population */
sme_loans AS (
    SELECT DISTINCT
        l.customer_id,
        l.loan_contract_id,
        l.disbursement_date
    FROM sme_loans_source l
),

/* 2. Pre-origination operating cash inflows */
operating_transactions AS (
    SELECT DISTINCT
        t.party_id,
        c.party_name,
        t.account_number,
        t.counterparty_party_id,
        t.counterparty_account_number,
        t.counterparty_account_name,
        l.loan_contract_id,
        l.disbursement_date,
        t.transaction_date,
        t.transaction_time,
        ABS(t.transaction_amount) AS transaction_amount
    FROM corporate_account_transactions t

    INNER JOIN sme_loans l
        ON l.customer_id = t.party_id

    LEFT JOIN corporate_customer_master c
        ON c.party_id = t.party_id

    CROSS JOIN params p

    WHERE t.debit_credit_code = 'CREDIT'

      AND t.transaction_date >=
          l.disbursement_date
          - p.lookback_days * INTERVAL '1 day'

      AND t.transaction_date <= l.disbursement_date

      AND c.party_name <> t.counterparty_account_name

      /* Exclude identifiable non-operating inflows */
      AND COALESCE(t.counterparty_account_name, '')
          NOT LIKE '%BANK%'

      AND COALESCE(t.transaction_memo, '')
          NOT LIKE '%LOAN%'

      AND COALESCE(t.transaction_memo, '')
          NOT LIKE '%REDEMPTION%'

      AND COALESCE(t.transaction_memo, '')
          NOT LIKE '%REPAYMENT%'

      AND COALESCE(t.transaction_memo, '')
          NOT LIKE '%BORROWING%'

      AND COALESCE(t.transaction_memo, '')
          NOT LIKE '%REFUND%'

      AND COALESCE(t.transaction_memo, '')
          NOT LIKE '%SALARY%'

      AND COALESCE(t.transaction_memo, '')
          NOT LIKE '%DEPOSIT REFUND%'
),

/* 3. Total operating inflow */
total_operating_inflow AS (
    SELECT
        party_id,
        party_name,
        account_number,
        loan_contract_id,
        disbursement_date,
        SUM(transaction_amount) AS total_operating_inflow
    FROM operating_transactions
    GROUP BY
        party_id,
        party_name,
        account_number,
        loan_contract_id,
        disbursement_date
),

/* 4. Related enterprises within the same credit group */
related_enterprises AS (
    SELECT DISTINCT
        borrower.party_id AS borrower_id,
        related.party_id AS related_party_id,
        related.party_name AS related_party_name
    FROM credit_group_relationships borrower

    INNER JOIN credit_group_relationships related
        ON borrower.group_id = related.group_id

    CROSS JOIN params p

    WHERE borrower.effective_date = p.snapshot_date
      AND related.party_id <> borrower.party_id
),

/* 5. Transactions sourced from related enterprises */
related_party_transactions AS (
    SELECT DISTINCT
        ot.party_id,
        ot.party_name,
        ot.account_number,
        ot.loan_contract_id,
        ot.disbursement_date,
        ot.transaction_date,
        ot.transaction_time,
        ot.transaction_amount,
        ot.counterparty_account_name
    FROM operating_transactions ot

    INNER JOIN related_enterprises re
        ON re.borrower_id = ot.party_id
       AND re.related_party_name = ot.counterparty_account_name
),

/* 6. Related-party operating inflow */
related_party_inflow AS (
    SELECT
        party_id,
        party_name,
        account_number,
        loan_contract_id,
        disbursement_date,
        SUM(transaction_amount) AS related_party_operating_inflow
    FROM related_party_transactions
    GROUP BY
        party_id,
        party_name,
        account_number,
        loan_contract_id,
        disbursement_date
),

/* 7. Calculate concentration */
risk_metrics AS (
    SELECT
        t.party_id AS sme_customer_id,
        t.party_name AS sme_customer_name,
        t.account_number,
        t.loan_contract_id,
        t.disbursement_date AS loan_disbursement_date,

        t.total_operating_inflow,

        COALESCE(r.related_party_operating_inflow, 0)
            AS related_party_operating_inflow,

        CASE
            WHEN t.total_operating_inflow = 0 THEN NULL
            ELSE
                COALESCE(r.related_party_operating_inflow, 0)
                / t.total_operating_inflow
        END AS related_party_inflow_ratio

    FROM total_operating_inflow t

    LEFT JOIN related_party_inflow r
        ON r.party_id = t.party_id
       AND r.account_number = t.account_number
       AND r.loan_contract_id = t.loan_contract_id
       AND r.disbursement_date = t.disbursement_date
)

/* 8. Final exception population */
SELECT
    rm.*,

    'High Related-Party Cash Flow Concentration' AS risk_flag

FROM risk_metrics rm
CROSS JOIN params p

WHERE rm.related_party_inflow_ratio
      >= p.related_party_ratio_threshold

ORDER BY
    rm.related_party_inflow_ratio DESC,
    rm.related_party_operating_inflow DESC,
    rm.total_operating_inflow DESC;
