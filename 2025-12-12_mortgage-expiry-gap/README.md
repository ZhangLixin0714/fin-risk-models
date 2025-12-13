# Corporate Loan — Mortgage Contract Expiry Does Not Cover Loan Tenor

📅 **Date:** 2025-12-12  
📂 **Category:** Corporate Credit Risk / Collateral Management  
🎯 **Use case:** Identify corporate loans where the **mortgage contract expiry date is earlier than the loan maturity date**, resulting in an uncovered collateral period.

---

## 🧠 Objective
Detect loans where the **legal effectiveness of collateral expires before the loan is fully repaid**, exposing the bank to:

- Unsecured tail risk;
- Regulatory non-compliance;
- Weak post-loan collateral management;
- Elevated loss given default (LGD).

This model produces a clear exception list for remediation, renewal, or risk reclassification.

---

## 🔍 Detection Logic

A loan is flagged if all conditions below are met:

1. Product category = **Corporate Loan**;
2. Collateral type includes **Mortgage**;
3. `mortgage_contract_expiry_date < loan_maturity_date`;
4. Loan status = active (optionally include overdue or special-mention loans).

Optional enhancements:
- Flag severity by **gap days**;
- Cross-check loan risk classification;
- Prioritize loans with large balances or weak guarantors.

---

## 🗂️ Required Tables (Generic)

| Table | Key Fields | Description |
|------|-----------|-------------|
| `loans` | loan_id, customer_id, product_category, origination_date, maturity_date, current_balance, risk_class, org_id | Loan master |
| `mortgage_contracts` | loan_id, contract_id, collateral_id, expiry_date | Mortgage contract registry |
| `collateral` | collateral_id, collateral_type, collateral_value | Collateral details |
| `party` | customer_id, customer_name | Corporate borrower info |
| `org_hierarchy` | org_id, level1/2/3 | Branch hierarchy |

---

## ⚙️ Parameters

| Parameter | Description |
|----------|-------------|
| `:REPORT_DATE` | snapshot date |
| `:OBS_START_DATE` | lower bound for loans |
| `:MIN_GAP_DAYS` | minimum uncovered days to flag |
| `:INCLUDE_OVERDUE_ONLY` | Y/N — restrict to overdue loans |

---

## 📤 Output Fields

- Branch hierarchy (L1–L3)  
- `loan_id`, `customer_id`, `customer_name`  
- `loan_maturity_date`  
- `mortgage_contract_expiry_date`  
- `gap_days`  
- `current_balance`  
- `risk_class`  
- Severity tag

---

## 📝 Notes

- Highly relevant for **regulatory inspections**, internal audits, and collateral renewal campaigns.  
- Can be combined with valuation updates to assess uncovered exposure.  
- Suitable KPI: % of corporate loan balance with collateral expiry gaps.
