# Newly Originated Loans — Short-Term Credit Deterioration Detection

**Date:** 2026-09-06  
**Category:** Credit Risk / Early Warning / Post-Origination Monitoring  
**Use case:** Identify newly originated loans that experience overdue status or material credit deterioration within approximately one year after a new lending relationship or loan origination.

---

## Objective

This model identifies loans that deteriorate shortly after a new credit relationship is established or a new loan is originated.

The analysis measures the time between:

- the establishment of a new lending relationship or new loan origination; and
- the first observed overdue event.

Loans with deterioration occurring within approximately **360–365 days** are selected for further review.

Short-term deterioration after origination may warrant investigation of:

- underwriting quality;
- borrower repayment capacity;
- potential misrepresentation at origination;
- channel or branch-level risk;
- rapid deterioration in borrower financial condition.

The model is designed as a **risk-screening and review tool**, rather than proof of underwriting failure or fraud.

---

## Detection Logic

### Population 1 — Loan-level early deterioration

1. Identify outstanding loans with non-zero balances.
2. Identify the first relevant overdue event for each loan agreement.
3. Identify the customer's earliest new credit-relationship date.
4. Calculate:

`days_to_deterioration = first_overdue_date - new_credit_relationship_date`

5. Retain cases where:

`days_to_deterioration <= 360`

---

### Population 2 — Newly originated loans becoming materially impaired

1. Identify loans with overdue principal.
2. Determine the earliest overdue date for each loan agreement.
3. Determine the customer's earliest loan origination date in the observation window.
4. Restrict the population to loans whose five-grade classification falls within configured adverse categories.
5. Calculate:

`days_to_deterioration = first_overdue_date - new_loan_date`

6. Retain cases where:

`days_to_deterioration <= 365`

---

## Required Data

| Dataset | Key Fields | Purpose |
|---|---|---|
| `loan_master` | loan_id, contract_id, customer_id, balance, origination_date, maturity_date | Core loan information |
| `loan_event_history` | contract_id, event_date, event_type | Identifies first overdue / deterioration event |
| `customer_loan_history` | customer_id, origination_date | Identifies new lending relationship |
| `loan_risk_classification` | loan_id, risk_class | Provides five-grade classification |
| `customer_master` | customer_id, customer_name | Customer information |
| `org_hierarchy` | org_id, level1_name, level2_name, branch_name | Organization labels |

---

## Key Output Fields

- `level1_branch`
- `level2_branch`
- `business_org`
- `customer_id`
- `customer_name`
- `loan_contract_id`
- `loan_id`
- `loan_balance`
- `currency_code`
- `accounting_subject`
- `original_loan_amount`
- `loan_origination_date`
- `contractual_maturity_date`
- `adjusted_maturity_date`
- `first_overdue_date`
- `new_credit_relationship_date`
- `days_to_deterioration`
- `loan_type`
- `product_code`
- `five_grade_classification`
- `overdue_principal`

---

## Risk Interpretation

A short time from origination to overdue status can be an important early-warning indicator.

However, a flagged record should not automatically be interpreted as fraud or poor underwriting. Further review may consider:

- borrower financial deterioration;
- unexpected external events;
- loan restructuring;
- repayment source changes;
- collateral deterioration;
- origination channel;
- branch or relationship-manager concentration.

---

## Potential Extensions

This rule can be extended into broader portfolio analytics such as:

1. **Early Deterioration Rate (EDR)** by origination vintage;
2. Deterioration rates by branch, product, or channel;
3. 30/90/180/365-day deterioration buckets;
4. Relationship between early deterioration and underwriting characteristics;
5. Vintage curves and time-to-default analysis.

---

## Disclaimer

This repository contains generalized financial risk-monitoring logic for research and educational purposes. Table names, field names, classification codes, thresholds, and implementation details are illustrative and should be adapted to the user's own data environment.
