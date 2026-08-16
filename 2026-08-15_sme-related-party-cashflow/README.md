SME Operating Cash Flows Primarily Sourced from Related Enterprises

Date: 2026-08-15
Category: SME Credit Risk / Related-Party Risk / Cash-Flow Verification
Use case: Identify SME borrowers whose pre-origination operating cash inflows are predominantly sourced from related enterprises within the same credit group.

Objective

This model evaluates the independence and authenticity of an SME borrower’s operating cash flows before loan origination.

It identifies borrowers for which a significant proportion of operating inflows during the 180 days preceding loan disbursement originates from related enterprises within the same credit group.

A high concentration of related-party inflows may indicate:

* Dependence on affiliated companies rather than independent business operations;
* Potential artificial enhancement of account turnover before loan origination;
* Intra-group fund transfers presented as operating cash flows;
* Weak standalone repayment capacity; or
* A need for enhanced review of the borrower’s actual operating activities and sources of repayment.

The model is intended as a risk-screening indicator rather than evidence of misconduct. Related-party transactions may have legitimate commercial purposes and should be reviewed together with underlying transaction documentation.

Detection Logic

Step 1 — Define the SME loan population

Identify SME borrowers and their loan contracts, including:

* borrower ID;
* borrower name;
* operating account;
* loan contract number; and
* loan disbursement date.

Step 2 — Capture pre-origination cash inflows

For each SME borrower, retrieve incoming account transactions occurring during the:

180 days before loan disbursement through the disbursement date.

Exclude transactions that are unlikely to represent genuine operating revenue, such as identifiable:

* bank-related transfers;
* loan proceeds;
* redemptions;
* repayments;
* borrowings;
* refunds;
* salary payments; and
* deposit refunds.

Aggregate the remaining transactions to calculate:

total_operating_inflow

Step 3 — Identify related enterprises

Use the credit-group relationship table to identify enterprises belonging to the same group as the SME borrower.

Match transaction counterparties against those related enterprises.

Step 4 — Calculate related-party operating inflows

Aggregate qualifying incoming transactions from related enterprises:

related_party_inflow

Step 5 — Calculate concentration ratio

Calculate:

related_party_inflow_ratio = related_party_inflow / total_operating_inflow

Step 6 — Flag high-concentration borrowers

Flag the borrower when:

related_party_inflow_ratio >= 50%

The threshold can be parameterized for different monitoring or audit scenarios.

Required Data

Dataset	Key Fields	Purpose
SME loan population	customer_id, loan_contract_id, disbursement_date	Defines borrowers and loan origination dates
Corporate account transactions	party_id, account_id, counterparty_name, transaction_date, transaction_amount, memo	Calculates pre-origination operating inflows
Corporate customer master	party_id, party_name	Borrower identification
Credit-group relationships	party_id, group_id, related_party_name	Identifies related enterprises

Parameters

Parameter	Description	Default
:LOOKBACK_DAYS	Number of days before loan disbursement	180
:RELATED_PARTY_RATIO_THRESHOLD	Minimum related-party inflow concentration	0.50
:SNAPSHOT_DATE	Effective date for group relationships	Reporting date

Output Fields

* sme_customer_id
* sme_customer_name
* account_number
* loan_contract_id
* loan_disbursement_date
* total_operating_inflow
* related_party_operating_inflow
* related_party_inflow_ratio
* risk_flag

Risk Interpretation

A high related-party inflow ratio does not automatically indicate fraud.

Instead, it serves as an enhanced due-diligence signal. Reviewers may further examine:

* underlying contracts and invoices;
* commercial relationships between group companies;
* transaction frequency and timing;
* concentration immediately before loan origination;
* circular fund flows;
* ultimate sources of repayment; and
* whether reported operating revenue reflects genuine external business activity.

Potential Extensions

The model can be extended to detect:

1. Sudden increases in related-party inflows immediately before loan applications;
2. Circular flows among the borrower and affiliated companies;
3. Same-day or short-window fund inflow/outflow patterns;
4. Related-party concentration trends across multiple loan originations;
5. Borrowers whose external third-party operating inflows are insufficient to support reported business scale.

Disclaimer

This repository contains generalized risk-monitoring logic for research and educational purposes. Table names, field names, thresholds, and implementation details are illustrative and should be adapted to the user’s data environment and applicable regulatory requirements.
