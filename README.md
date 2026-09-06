# fin-risk-models

**Open-source SQL and AI-based models for financial risk detection, fraud analytics, and regulatory compliance.**

This repository curates a collection of practical, modular, and ready-to-use models for identifying financial risks across domains like:

- ✅ Fraudulent lending behavior
- ✅ Anti-money laundering (AML)
- ✅ Credit risk concentration
- ✅ Transaction network anomalies
- ✅ Graph-based customer relationship risk

Each model includes:
- Well-documented SQL logic or algorithm
- A sample use case or detection scenario
- Parameters you can adjust
- English markdown explanation (and optionally citations)

---

## 📦 Available Models

| Date | Model Title | Description |
|------|-------------|-------------|
| 2025-07-29 | [Multiple Second-Hand-Mortgage Payouts to the Same Payee](./2025-07-29_multi-secondhand-mortgage/README.md) | Flags suspicious clusters where many borrowers share the same recipient account — a red flag for organised fraud. |
| 2025-09-05 | [Personal Loans — Concentrated Proceeds to a Single Counterparty (Branch-Level)](./2025-09-05_concentrated-loan-proceeds/README.md) | Detects cases where multiple personal loans are funneled into the same counterparty account within the same branch — useful for spotting fund-pooling, straw-buyer rings, or collusion. |
| 2025-09-06 | [Employee Self-Involvement in Own Loan Workflow](./2025-09-06_employee-self-involvement/README.md) | Flags loans where employees act on their own loan workflows — conflict-of-interest risk |
| 2025-09-07 | [Personal Business Loan — First-Year Delinquency After Origination](./2025-09-07_personal-business-loan-first-year-delinquency/README.md) | Flags personal business loans that become delinquent within the first year — key KPI for underwriting and channel risk. |
| 2025-09-11 | [Personal Loan — Quarter-End Origination & Early Next-Quarter Payoff](./2025-09-11_quarter-end-origination/README.md) | Flags quarter-end loans that are quickly repaid at the start of the next quarter — potential “window dressing” risk. |
| 2025-09-17 | [Mortgage — Large Card Installment in the 90 Days Pre-Disbursement](./2025-09-17_mortgage-pre-disbursement-card-installment/README.md) | Flags borrowers with sizable card-installments shortly before interest start — a signal of hidden liabilities or cash-flow stress. |
| 2025-09-26 | [Personal Loans — Overdue Post-Loan Task Backlog](./2025-09-26_overdue-post-loan-task-backlog/README.md) | Flags branches/officers with sustained backlogs of overdue post-loan tasks (weak controls, higher future risk). |
| 2025-10-15 | [Corporate Loans Used to Settle the Company’s Own Maturing Trade Bills](./2025-10-15_corp-loan-bill-redemption/README.md) | Matches loans within N days before a bill maturity (same company) where loan ≈ bill amount — signals liquidity recycling. |
| 2025-10-16 | [Corporate Trade Bill Issuance — Full-Portfolio Monitoring](./2025-10-16_corporate-bill-issuance/README.md) | Aggregates and flags abnormal corporate bill issuance versus loan exposure or historical trends. |
| 2025-10-17 | [SME Trade Bill Issuance — Monitoring Model](./2025-10-17_sme-bill-issuance/README.md) | Flags small & micro enterprises with abnormal bill issuance volume or ratios versus loan exposure. |
| 2025-11-02 | [Trade Bill Redemption — Advance Payment Detection](./2025-11-02_bill-redemption-advance/README.md) | Detects bills redeemed through third-party or bank advance payments prior to maturity, indicating potential hidden rollover risk. |
| 2025-11-14 | [Discount Financing — Artificial Green Classification (CRC Correction Category)](./2025-11-14_discount-green-classification-correction/README.md) | Detects enterprises whose green classification is inconsistent with financing behavior, especially discount flows contradicting green use-of-funds. |
| 2025-11-30 | [E-Collateral Quick Loan — Classified Assets (Substandard / Doubtful / Loss)](./2025-11-30_ecollateral-npl-classification/README.md) | Extracts and profiles NPL-classified E-Collateral Quick Loans for asset-quality monitoring. |
| 2025-12-12 | [Corporate Loan — Mortgage Contract Expiry Does Not Cover Loan Tenor](./2025-12-12_mortgage-expiry-gap/README.md) | Flags corporate loans where mortgage contracts expire before loan maturity, creating uncovered collateral risk. |
| 2025-12-24 | [Corporate Loan — Notes with Significant Provision Fluctuations](./2025-12-24_corporate-loan-provision-volatility/README.md) | Flags corporate loan notes with abnormal provisioning changes, supporting asset quality and accounting risk reviews. |
| 2026-01-25 | [SME Borrowers (Non-NPL) with External Fraud Events](./2026-01-25_sme-external-fraud-events-non-npl/README.md) | Identifies performing SME borrowers with external fraud, litigation, or dishonesty events as early warning signals. |
| 2026-04-14 | [Entrusted Loans — Multiple Different Principals Funding the Same Borrower](./2026-04-14_multiple-principals-same-borrower/README.md) | Flags borrowers receiving entrusted-loan funding from multiple distinct principals, highlighting look-through concentration risk. |
| 2026-05-04 | [SME Corporate Loans — Time from Origination to NPL](./2026-05-04_sme-loan-time-to-npl/README.md) | Measures time-to-default and flags early default loans, indicating underwriting or fraud risk. |
| 2026-08-15 | [SME Operating Cash Flows Primarily Sourced from Related Enterprises](./2026-08-15_sme-related-party-cashflow/README.md) | Identifies SME borrowers whose pre-origination operating inflows are predominantly sourced from related enterprises, highlighting business-independence and cash-flow authenticity risks. |
| 2026-08-30 | [Corporate Loans — Interest Collection Configuration Anomaly Review](./2026-08-30_corporate-loan-interest-collection-review/README.md) | Builds a review population of corporate loans with selected interest-period configurations and exposes pricing, overdue-interest, repayment and agreement-linkage fields for detecting potential interest collection anomalies. |
| 2026-09-06 | [Newly Originated Loans — Short-Term Credit Deterioration Detection](./2026-09-06_new-loan-short-term-deterioration/README.md) | Identifies newly originated loans that become overdue or materially deteriorate within approximately one year, supporting underwriting-quality and early-warning analysis. |

_(New models added daily. See commit history or Releases for changelog.)_

---

## 📌 How to Use

Clone or download individual model folders. Each one includes:
- `.sql` (or `.ipynb`) — the core logic
- `README.md` — usage and explanation

If you find these useful, please ⭐️ the repo or cite it in your work.

---

## 📖 License

This project is licensed under the Apache 2.0 License — feel free to adapt and reuse with attribution.

---

## 👤 Author

Maintained by [@ZhangLixin0714](https://github.com/ZhangLixin0714)  
I work at the intersection of **risk modeling**, **regulatory tech**, and **AI for finance**, and share these models in support of community growth and my NIW petition. Feedback and contributions are welcome!
