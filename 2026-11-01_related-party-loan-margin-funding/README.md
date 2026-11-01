
# Potential Funding of Bank Acceptance Margins from Related-Party Corporate Loans

**Date:** 2026-11-01
**Category:** Corporate Credit Risk / Related-Party Risk / Loan Proceeds Monitoring
**Model type:** Credit-group and temporal association screen

## Objective

Identify cases in which company A deposits funds into a bank acceptance margin account shortly after **another company B in the same credit group** receives a corporate loan.

This is a risk-screening model, **not** transaction-level evidence that company B's loan financed company A's margin deposit.

## Detection Logic

1. Select bank acceptance and electronic bank acceptance margin deposits in the observation window.
2. Resolve the depositing company's credit-group membership using the reporting-date group snapshot.
3. Identify **different legal entities** belonging to the same group (`margin_customer_id <> related_borrower_id`).
4. Retrieve corporate loan disbursements to those related entities during the observation window.
5. Calculate `days_between_disbursement_and_margin = margin_deposit_date - loan_disbursement_date`.
6. Retain observations where `0 <= days_between_disbursement_and_margin <= LOOKBACK_DAYS`.
7. Report the group, both companies, margin deposit details, corporate loan details, dates, and institution labels.

**Scope note:** The original query includes the margin status as an output field, but **does not filter the result to active/normal margin accounts**. This reference implementation preserves that distinction.

## Required Data

| Dataset | Important fields | Purpose |
|---|---|---|
| `acceptance_margin_history` | `customer_id`, `deposit_date`, `margin_id`, `margin_amount_minor_units`, `acceptance_type`, `margin_status` | Margin deposit records |
| `credit_group_membership_snapshot` | `group_id`, `customer_id`, `snapshot_date` | Group membership |
| `corporate_customer_master` | `customer_id`, `customer_name`, `snapshot_date` | Names for group members |
| `corporate_loan_snapshot` | `customer_id`, `contract_id`, `loan_note_id`, `disbursement_date`, `original_loan_amount` | Loans to related companies |
| `organization_hierarchy` | `org_id`, `branch_name`, `subbranch_name`, `outlet_name` | Margin account institution |

## Parameters

| Parameter | Meaning |
|---|---|
| `:START_DATE` | Observation start (inclusive) |
| `:END_DATE` | Observation end and snapshot date (inclusive) |
| `:LOOKBACK_DAYS` | Maximum number of calendar days from related-party loan disbursement to margin deposit |

## Key Outputs

- Credit group ID;
- Margin depositor (company A) ID/name;
- Related corporate borrower (company B) ID/name;
- Margin account, deposit date, deposit amount, status, and type;
- Loan contract, note, account, disbursement date, original amount, and currency;
- Number of days between loan disbursement and margin deposit;
- Margin branch and review indicator.

## Interpretation and Follow-up

A flagged match indicates **group affiliation plus temporal proximity**. It does not establish an actual transfer or misuse of funds.

Reviewers should trace the proceeds from company B's disbursement account through intermediate accounts, test whether funds reached company A or its margin account, reconcile amounts and currencies, and inspect the loan purpose restrictions and legitimate related-party transactions.

## Limitations

- No transaction-level funds-flow tracing is performed.
- Multiple group members or loan notes may yield multiple candidate matches for one margin deposit.
- Group membership is assessed at the reporting snapshot, not necessarily at the date of each event.
- The reference query restricts loan records to the reporting-date snapshot; records absent from that snapshot may be missed.
- The source divides the margin amount by 100; confirm whether the feed stores amounts in minor currency units.
- The original historical-record validity conditions are preserved conceptually but may require adaptation to the target database's versioning model.
- The two companies' currencies and amounts are not required to match, reflecting the original screening approach.
- This SQL is a generalized PostgreSQL reference, not a production-validated query.

## Related Model

[Potential Funding of Bank Acceptance Margins from Corporate Loans (2026-10-25)](../2026-10-25_bank-acceptance-margin-funding/README.md) screens the **same-company** relationship. This model extends screening to **different companies in the same credit group**.

## Disclaimer

Generalized research and educational implementation. Institutional identifiers, source table schemas, and proprietary codes have been replaced with illustrative names and categories. Publication should comply with all applicable employer confidentiality, intellectual property, and data-use obligations.
