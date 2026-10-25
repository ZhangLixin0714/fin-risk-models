
# Potential Funding of Bank Acceptance Margins from Corporate Loans

**Date:** 2026-10-25
**Category:** Corporate Credit Risk / Loan Proceeds Monitoring / Bank Acceptance Margin Review
**Model type:** Temporal Association and Exception Review

## Objective

Identify corporate borrowers that deposit bank acceptance margins shortly after receiving a corporate loan.

A close temporal association may warrant an investigation of whether loan proceeds were used to fund the margin. However, the model does not establish that funds were actually transferred between the accounts.

## Detection Logic

### Step 1 — Identify bank acceptance margin deposits

Retrieve margin deposit records that:

- Occur within the observation period;
- Relate to ordinary or electronic bank acceptances;
- Have an active account status;
- Meet the applicable source-record validity conditions.

### Step 2 — Retrieve corporate loan disbursements

Select corporate loans originated within the observation period from the reporting-date loan snapshot.

### Step 3 — Match borrowers

Link the margin deposits and loan disbursements using the same borrower/customer identifier.

### Step 4 — Calculate the time interval

`days_between_disbursement_and_margin = margin_deposit_date - loan_disbursement_date`

### Step 5 — Apply the observation threshold

Retain records where:

`0 <= days_between_disbursement_and_margin <= LOOKBACK_DAYS`

### Step 6 — Generate the review population

Output borrower information, loan details, margin deposit information, organization hierarchy and elapsed days.

## Required Data

| Dataset | Key Fields | Purpose |
|---|---|---|
| `acceptance_margin_history` | customer_id, deposit_date, acceptance_type, margin_status, amount_minor_units | Margin deposit information |
| `corporate_loan_snapshot` | customer_id, disbursement_date, original_loan_amount, contract_id, loan_note_id | Corporate loan disbursements |
| `organization_hierarchy` | org_id, branch_name, subbranch_name, outlet_name | Organization information |

## Parameters

| Parameter | Description |
|---|---|
| `:START_DATE` | Beginning of observation period |
| `:END_DATE` | End of observation period and reporting snapshot date |
| `:LOOKBACK_DAYS` | Maximum number of calendar days between loan disbursement and margin deposit |

## Output Fields

The model returns:

- Branch and organization hierarchy;
- Borrower ID and borrower name;
- Loan contract, loan note and loan account;
- Loan disbursement and maturity dates;
- Original loan amount and currency;
- Bank acceptance margin account and identifier;
- Margin deposit date, amount, currency and account status;
- Margin funding and settlement account references;
- Days between loan disbursement and margin deposit;
- Exception review indicator.

## Risk Interpretation

A flagged record indicates that a borrower deposited bank acceptance margin funds shortly after receiving a corporate loan.

Potential concerns include:

- Possible diversion of loan proceeds;
- Inadequate verification of loan proceeds usage;
- Potential circumvention of credit-use restrictions;
- Intra-company account transfers requiring further examination.

A flagged case is not, by itself, evidence of a contractual or regulatory violation.

## Follow-up Review

Investigators should:

1. Trace the disbursed loan proceeds through transaction-level account records.
2. Identify any intermediary accounts.
3. Reconcile transaction dates and amounts.
4. Compare fund transfers with margin funding account credits.
5. Review relevant use-of-proceeds restrictions and supporting documents.
6. Determine whether the apparent relationship is supported by actual funds-flow evidence.

## Limitations

- Matching uses borrower identity and date proximity, not direct funds tracing.
- A single margin deposit may match more than one recently disbursed loan.
- The model does not establish that a particular loan financed a particular margin.
- Reporting-date snapshots may omit certain previously originated loans.
- Product classifications and account status codes are illustrative.
- Currency and amount units must be validated before deployment.

## Disclaimer

This repository contains generalized financial risk-monitoring logic for research and educational purposes. Table names, field names, account codes, thresholds and implementation details are illustrative. The SQL has not been production-validated.
