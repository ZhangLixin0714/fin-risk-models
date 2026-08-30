# Corporate Loans — Interest Collection Configuration Anomaly Review

**Date:** 2026-08-30  
**Category:** Corporate Credit Risk / Interest Accrual & Collection Controls  
**Use case:** Review corporate loans with selected interest-period configurations and identify records requiring further validation of interest collection, pricing, delinquency, and agreement linkage.

---

## Objective

This model extracts corporate loan records that meet specified interest-period and account-type conditions and consolidates key information needed to review potential interest collection anomalies.

The model supports examination of:

- Interest-period configuration;
- Loan start and maturity dates;
- Interest-rate and repricing settings;
- Outstanding principal and overdue principal;
- On-balance-sheet and off-balance-sheet overdue interest;
- Loan risk classification;
- Repayment frequency and repayment mode;
- Agreement and related-party mappings.

The output is intended as a **review population**. It does not, by itself, prove that interest was collected incorrectly.

---

## Detection Logic

### Step 1 — Identify target loan accounts

Select loan accounts that:

- belong to the configured loan account type;
- use one of the selected interest-period codes;
- have an interest start date on or after the observation start date; and
- meet the configured agreement-scope criteria.

### Step 2 — Resolve agreement-party relationships

Map the loan agreement through the relevant agreement-party and party-relationship records to identify the associated customer.

### Step 3 — Join corporate loan details

Enrich the selected agreements with:

- loan contract ID;
- loan note ID;
- product;
- accounting subject;
- customer;
- currency;
- principal balance;
- origination and maturity dates;
- repayment date;
- repricing date;
- risk classification;
- loan purpose;
- repayment configuration;
- interest-rate configuration;
- cumulative disbursement and repayment;
- write-off information;
- overdue principal and overdue interest.

### Step 4 — Add organization and product labels

Attach branch hierarchy and product descriptions for review and aggregation.

---

## Required Data

| Dataset | Key Fields | Purpose |
|---|---|---|
| `loan_account_history` | agreement_id, interest_period_code, start_interest_date, maturity_date, account_type | Identifies target loan accounts |
| `agreement_party_relationships` | agreement_id, party_id, relationship_type | Maps agreements to parties |
| `party_relationships` | party_id, related_party_id, relationship_type | Resolves customer relationships |
| `corporate_loan_agreements` | loan_id, agreement_id, customer_id, principal_balance, risk_class | Core corporate loan information |
| `customer_master` | customer_id, customer_name | Customer identification |
| `product_catalog` | product_id, product_name | Product description |
| `org_hierarchy` | org_id, level1_name, level2_name, level3_name | Branch hierarchy |

---

## Review Fields

The review output includes:

- branch hierarchy;
- agreement ID;
- loan contract ID;
- loan note ID;
- product ID and product name;
- customer ID and customer name;
- interest period;
- interest start date;
- maturity date;
- repricing date;
- loan interest rate;
- overdue interest rate;
- principal balance;
- overdue principal balance;
- on-balance-sheet overdue interest;
- off-balance-sheet overdue interest;
- principal overdue periods;
- interest overdue periods;
- five-grade and detailed risk classifications.

---

## Risk Interpretation

Potential anomalies may warrant further review when the extracted records show unusual combinations such as:

- unexpected interest-period configuration;
- interest overdue while principal remains current;
- significant overdue interest with low or zero overdue principal;
- inconsistent repricing or interest-rate settings;
- unexpected agreement-party mappings;
- unusually high interest overdue periods.

These conditions should be validated against contractual terms and actual transaction-level interest postings before concluding that an interest collection error occurred.

---

## Possible Extensions

This review model can be extended into a full reconciliation model by adding:

1. Contractual interest calculation;
2. Actual interest posting and collection transactions;
3. Expected-versus-actual interest comparison;
4. Tolerance thresholds;
5. Automatic exception severity scoring.

A full reconciliation version could calculate:

`interest_difference = actual_interest_collected - expected_interest_due`

and flag records where the absolute difference exceeds a configured tolerance.

---

## Disclaimer

This repository contains generalized risk-monitoring logic for research and educational purposes. Table names, field names, relationship codes, thresholds, and implementation details are illustrative and should be adapted to the user's own data environment and applicable regulatory requirements.
