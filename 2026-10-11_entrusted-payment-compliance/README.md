Loan Disbursement — Potential Entrusted Payment Non-Compliance Detection

Date: 2026-10-11
Category: Loan Disbursement Controls / RegTech / Internal Audit
Status: Illustrative, not production-validated

Objective

Identify corporate-loan disbursements for which the prescribed entrusted payment to the contractually designated counterparty cannot be matched to an actual debit transaction during the configured post-disbursement window. The result is an investigation lead, not proof of a contract breach.

Detection logic

1. Select current entrusted-payment instructions during the observation period where the expected payee account differs from the disbursement account.
2. Join instructions to loan-level origination and balance records at the selected snapshot.
3. Search for a debit from the disbursement account matching the instructed amount and counterparty account within the configurable payment window after interest commencement.
4. For the standard route, retain unmatched instructions only if the minimum observed post-disbursement account balance is below the original loan amount (an auxiliary indicator, not direct evidence of misuse).
5. For the special route, retain unmatched instructions for separate review. The original internal query used an account-code substring to distinguish the two routes; this public example replaces it with a placeholder payment_route_code. Configure this mapping before use.

Parameters

|Parameter             |Meaning                           |
|----------------------|----------------------------------|
|`:START_DATE`         |Beginning of observation period   |
|`:END_DATE`           |End of observation period         |
|`:SNAPSHOT_DATE`      |Loan snapshot date                |
|`:PAYMENT_WINDOW_DAYS`|Configured payment matching window|

Example input tables

• entrusted_payment_instructions: instructed payee, amount, purpose, route and source disbursement account
• corporate_loans: loan, contract, origination and balance attributes
• account_transactions: debit transactions with counterparty accounts
• account_balance_events: dated account balances after origination

These are illustrative schema names. Adapt field mappings, identifier normalization, amount signs, transaction reversals, and timestamp conventions to your environment.

Important limitations

• The supplied legacy query has inconsistent column aliases and repeated joins; this is a generalized reconstruction, not a line-for-line executable translation.
• The original matching logic used account-number prefixes and a bank-specific route code. This release deliberately does not expose those internal encoding conventions.
• A missing match may arise from delayed processing, alternate authorized payment routes, account formatting, partial payments, or data gaps.
• The current SQL uses exact amount and account matches; production implementations may need split-payment aggregation, reversals, multiple currencies, and approved exceptions.
• The source SQL contains a second branch whose exact balance-filter behavior is not identical to the first; preserve and verify these business-specific distinctions before deployment.
• No sample dataset or actual execution results are included. Validate against approved test cases before production use.

Suggested review steps

Confirm the contractual payment requirement; reconcile actual debit transactions and authorized exceptions; review borrower disbursement-account movements; verify timing and recipient identity; document case-level findings.

Disclaimer

For educational and research use. No internal production schema or sensitive customer information is provided. A flagged record is not a confirmed regulatory violation.
