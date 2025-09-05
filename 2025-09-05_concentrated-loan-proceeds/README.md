# Personal Loans — Concentrated Proceeds to a Single Counterparty (Branch-Level)

📅 **Date:** 2025-09-05  
📂 **Category:** Personal Loan Risk Monitoring  
🏦 **Scope:** Branch-level aggregation  
🧭 **Use case:** Detecting potential fund-pooling, straw-buyer rings, or merchant collusion.

---

## 🧠 Objective

Flag cases where multiple borrowers’ personal loan proceeds are funneled into the **same counterparty account** within the **same branch** during a defined window — either through:

- **Entrusted payments**: loan directly paid to counterparty  
- **Self-managed payouts** followed by **onward transfer** within N days

---

## 🔍 Detection Logic

Flags any (branch, counterparty_account) pair where:

- Entrusted disbursement or self-managed onward transfer ≈ disbursement amount  
- Distinct borrowers ≥ `:MIN_DISTINCT_BORROWERS`  
- (Optional) Total fund flow ≥ `:MIN_TOTAL_FLOW`

---

## 🛠️ Required Tables

- `loans`, `loan_disbursements`, `account_transactions`
- `org_hierarchy` (for branch names), `product_catalog` (for product details)

---

## 🔧 Parameters

| Parameter | Description |
|----------|-------------|
| `:REPORT_DATE` | As-of label date |
| `:OBS_START_DATE` – `:OBS_END_DATE` | Observation window |
| `:SELF_FLOW_WINDOW_DAYS` | Transfer window after disbursement (default: 7) |
| `:AMOUNT_TOL_PCT` | Tolerance around disbursement (default: 20%) |
| `:MIN_DISTINCT_BORROWERS` | Minimum unique borrowers per branch-counterparty |
| `:MIN_TOTAL_FLOW` | (Optional) Minimum total flow |

---

## 📤 Output Fields

- Branch name: `level1_branch`, `level2_branch`, `level3_branch`  
- Counterparty: `counterparty_acct_id`, `distinct_borrowers`, `total_flow_amt`  
- Loan details: `loan_id`, `flow_date`, `flow_amount`, `flow_source`

---

## 🧩 Use Case Highlights

This rule is especially effective for:

- **Detecting collusive merchants**
- **Identifying fake demand/fraud rings**
- **Supporting post-loan forensic audits**

---

## ⚠️ Governance Tips

- Exclude trusted escrow/settlement hubs via safelist  
- Monitor changes in disbursement channel behavior  
- Add burstiness filters (e.g., short time window) for urgent patterns

---

## 📝 Citation

If used, please cite or ⭐ this repo to support open-source financial risk analytics.
