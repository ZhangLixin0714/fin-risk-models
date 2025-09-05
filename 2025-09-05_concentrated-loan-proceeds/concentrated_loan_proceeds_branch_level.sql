/*
------------------------------------------------------------
 Personal Loans - Concentrated Proceeds to a Single Counterparty
 Date: 2025-09-05
 Scope: Branch-level aggregation
 Objective:
   Detect cases where multiple borrowers' personal loan proceeds
   are funneled into the same counterparty account within the
   same branch during a short time window.

 Tables used:
   - loan_disbursement (loan_id, borrower_id, branch_id, disbursed_amount, disbursed_date, counterparty_account)
   - customer (borrower_id, name, id_number)
   - branch (branch_id, branch_name)

 Parameters:
   - :window_days → number of days to monitor (e.g. 7)
   - :threshold_count → minimum distinct borrowers funnelling into same account (e.g. 5)
------------------------------------------------------------
*/

WITH branch_level AS (
    SELECT
        ld.counterparty_account,
        ld.branch_id,
        COUNT(DISTINCT ld.borrower_id) AS borrower_count,
        SUM(ld.disbursed_amount) AS total_amount,
        MIN(ld.disbursed_date) AS first_date,
        MAX(ld.disbursed_date) AS last_date
    FROM loan_disbursement ld
    WHERE ld.disbursed_date >= DATEADD(DAY, -:window_days, CURRENT_DATE)
    GROUP BY ld.counterparty_account, ld.branch_id
)
SELECT
    b.branch_name,
    bl.counterparty_account,
    bl.borrower_count,
    bl.total_amount,
    bl.first_date,
    bl.last_date
FROM branch_level bl
JOIN branch b ON bl.branch_id = b.branch_id
WHERE bl.borrower_count >= :threshold_count
ORDER BY bl.borrower_count DESC, bl.total_amount DESC;
