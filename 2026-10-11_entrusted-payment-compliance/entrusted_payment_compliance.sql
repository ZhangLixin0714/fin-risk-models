
/* ==============================================================
   Model: Loan Disbursement — Potential Entrusted Payment
          Non-Compliance Detection

   Date: 2026-10-11

   Purpose:
   Identify corporate loans where entrusted payment instructions
   cannot be matched to actual account transfers within the
   required payment window.

   Notes:
   - Generalized PostgreSQL reference implementation.
   - All table and column names are vendor-neutral.
   - Internal account codes and institution-specific rules
     have been replaced with generic identifiers.
   - Findings are potential exceptions requiring verification.
   ============================================================== */

WITH params AS (
    SELECT
        CAST(:START_DATE AS DATE) AS start_date,
        CAST(:END_DATE AS DATE) AS end_date,
        CAST(:SNAPSHOT_DATE AS DATE) AS snapshot_date,
        CAST(:PAYMENT_WINDOW_DAYS AS INTEGER)
            AS payment_window_days
),

/* --------------------------------------------------------------
   1. Extract entrusted payment instructions
   -------------------------------------------------------------- */

entrusted_instructions AS (
    SELECT
        i.instruction_id,
        i.loan_id,
        i.customer_id,
        i.org_id,
        i.disbursement_account,
        i.expected_payee_account,
        i.expected_payee_name,
        i.payment_amount,
        i.payment_purpose,
        i.instruction_date,
        i.currency_code,
        i.payment_route_code

    FROM entrusted_payment_instructions i

    CROSS JOIN params p

    WHERE i.instruction_date >= p.start_date

      AND i.instruction_date <
          p.end_date + INTERVAL '1 day'

      AND i.expected_payee_account
          IS DISTINCT FROM i.disbursement_account

      AND i.is_current = TRUE
),

/* --------------------------------------------------------------
   2. Retrieve corporate loan records at reporting date
   -------------------------------------------------------------- */

loans_at_snapshot AS (
    SELECT
        l.loan_id,
        l.contract_id,
        l.origination_date,
        l.interest_start_date,
        l.maturity_date,
        l.loan_product,
        l.loan_rate,
        l.original_amount,
        l.outstanding_balance

    FROM corporate_loans l

    CROSS JOIN params p

    WHERE l.snapshot_date = p.snapshot_date
),

/* --------------------------------------------------------------
   3. Link entrusted payment instructions to loan records
   -------------------------------------------------------------- */

base AS (
    SELECT
        i.*,
        l.contract_id,
        l.origination_date,
        l.interest_start_date,
        l.maturity_date,
        l.loan_product,
        l.loan_rate,
        l.original_amount,
        l.outstanding_balance

    FROM entrusted_instructions i

    INNER JOIN loans_at_snapshot l
        ON l.loan_id = i.loan_id
),

/* --------------------------------------------------------------
   4. Identify matching actual payment transactions

   A matching payment must satisfy:
   - Same disbursement account
   - Debit transaction
   - Same payment amount
   - Same expected receiving account
   - Within the configured payment window
   -------------------------------------------------------------- */

matching_payments AS (
    SELECT
        b.instruction_id,

        MIN(t.transaction_date)
            AS first_matching_payment_date,

        COUNT(*) AS matching_transaction_count

    FROM base b

    INNER JOIN account_transactions t
        ON t.account_number = b.disbursement_account

       AND t.transaction_direction = 'DEBIT'

       AND t.transaction_amount = b.payment_amount

       AND t.counterparty_account =
           b.expected_payee_account

       AND t.transaction_date >= b.interest_start_date

       AND t.transaction_date <
           b.interest_start_date
           + (SELECT payment_window_days FROM params)
             * INTERVAL '1 day'

    GROUP BY
        b.instruction_id
),

/* --------------------------------------------------------------
   5. Retrieve minimum account balance after loan origination

   Used as a supplementary indicator of whether disbursed
   funds may have been transferred out of the account.
   -------------------------------------------------------------- */

post_disbursement_balance AS (
    SELECT
        b.instruction_id,

        MIN(h.end_of_event_balance)
            AS minimum_balance

    FROM base b

    INNER JOIN account_balance_events h
        ON h.account_number = b.disbursement_account

       AND h.event_date >= b.origination_date

       AND h.event_date <=
           (SELECT end_date FROM params)

    GROUP BY
        b.instruction_id
),

/* --------------------------------------------------------------
   6. Consolidate payment and account-balance evidence

   Preserve separate review paths for standard and special
   payment routing scenarios.
   -------------------------------------------------------------- */

review_population AS (
    SELECT
        b.*,

        m.first_matching_payment_date,
        m.matching_transaction_count,

        bal.minimum_balance,

        CASE
            WHEN b.payment_route_code = 'SPECIAL_ROUTE'
                THEN 'SPECIAL_ROUTE_REVIEW'

            ELSE 'STANDARD_ROUTE_REVIEW'
        END AS review_route

    FROM base b

    LEFT JOIN matching_payments m
        ON m.instruction_id = b.instruction_id

    LEFT JOIN post_disbursement_balance bal
        ON bal.instruction_id = b.instruction_id
)

/* --------------------------------------------------------------
   7. Final exception population

   Flag records with no matching entrusted payment.

   Standard route:
   Requires supplementary account-balance evidence.

   Special route:
   Retained for separate investigation according to
   the designated payment-routing logic.
   -------------------------------------------------------------- */

SELECT
    r.org_id,
    r.customer_id,
    r.loan_id,
    r.contract_id,

    r.instruction_id,
    r.loan_product,
    r.currency_code,

    r.origination_date,
    r.interest_start_date,
    r.maturity_date,

    r.original_amount,
    r.outstanding_balance,
    r.loan_rate,

    r.disbursement_account,
    r.expected_payee_account,
    r.expected_payee_name,

    r.payment_amount,
    r.payment_purpose,

    r.first_matching_payment_date,
    r.minimum_balance,

    r.review_route,

    'NO_MATCHING_ENTRUSTED_PAYMENT_WITHIN_WINDOW'
        AS exception_reason

FROM review_population r

CROSS JOIN params p

WHERE r.first_matching_payment_date IS NULL

  AND r.interest_start_date
      BETWEEN p.start_date AND p.end_date

  AND (
        (
            r.review_route = 'STANDARD_ROUTE_REVIEW'

            AND r.minimum_balance < r.original_amount
        )

        OR r.review_route = 'SPECIAL_ROUTE_REVIEW'
      )

ORDER BY
    r.org_id,
    r.customer_id,
    r.loan_id,
    r.interest_start_date;
