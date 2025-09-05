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
