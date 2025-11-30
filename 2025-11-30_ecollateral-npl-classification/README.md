# E-Collateral Quick Loan — Classified Assets (Substandard / Doubtful / Loss)

📅 **Date:** 2025-11-30  
📂 **Category:** Retail Credit Risk / Asset Quality  
🎯 **Use case:** Identify E-Collateral Quick Loan accounts classified as **Substandard**, **Doubtful**, or **Loss**, enabling targeted remediation, portfolio surveillance, and risk migration analysis.

---

## 🧠 Objective
This model extracts and profiles **non-performing exposures (NPE)** within the E-Collateral Quick Loan portfolio, focusing on:

- Detailing accounts classified into **Substandard**, **Doubtful**, or **Loss**;
- Providing actionable loan-level fields for remediation and workout teams;
- Tracking early warning indicators such as overdue bucket, restructuring status, and collateral value deterioration;
- Supporting branch-level accountability and asset-quality reporting.

---

## 🔍 Detection Logic

A loan is included in the output if:

1. Product type = *E-Collateral Quick Loan* (standardized category: `ECOLLATERAL_QUICK_LOAN`);
2. Latest regulatory classification ∈ {Substandard, Doubtful, Loss};
3. Loan status active or recently written-off (based on configuration);
4. Optional filters:
   - `days_past_due ≥ :DPD_MIN`,
   - or `classification_date ≥ :OBS_START_DATE`.

---

## 🗂️ Required Tables

| Table | Key Fields | Description |
|-------|------------|-------------|
| `loans` | loan_id, product_category, classification, classification_date, origination_date, current_balance, dpd, writeoff_flag, org_id | Core loan attributes |
| `collateral` | loan_id, collateral_type, collateral_value, update_date | E-collateral details |
| `party` | customer_id, customer_name, id_number | Customer registry |
| `org_hierarchy` | org_id, level1_name, level2_name, level3_name | Branch labeling |

---

## ⚙️ Parameters

| Parameter | Description |
|-----------|-------------|
| `:REPORT_DATE` | snapshot date |
| `:OBS_START_DATE` | classification window start |
| `:DPD_MIN` | minimum days past due (optional) |
| `:INCLUDE_WRITEOFF` | Y/N include written-off loans |

---

## 📤 Output Fields

- Branch hierarchy (L1–L3)  
- `loan_id`, `customer_id`, `customer_name`, `id_number`  
- Classification (`Substandard` / `Doubtful` / `Loss`)  
- `classification_date`  
- `dpd`, `current_balance`  
- Collateral type & latest collateral value  
- `writeoff_flag`  
- Risk severity tag

---

## 📝 Notes

- Collateral deterioration can be used to create additional severity flags.  
- Useful for NPL review packages, asset-quality dashboards, regulatory inspection preparation.  
