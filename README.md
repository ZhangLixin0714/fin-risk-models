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
