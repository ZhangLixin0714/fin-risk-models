# SME Corporate Loans — Time from Origination to NPL (Seasoning Risk Model)

📅 **Date:** 2026-05-04  
📂 **Category:** SME Credit Risk / Early Default Analysis  
🎯 **Use case:** Identify SME corporate loans that become **non-performing shortly after origination**, indicating weak underwriting, fraud risk, or rapid credit deterioration.

---

## 🧠 Objective

Measure the **time interval between loan origination and NPL classification**, and detect:

- Loans that turn bad unusually quickly (early default);
- Potential fraud or misrepresentation at origination;
- Weak credit approval or risk assessment;
- Structural issues in specific branches, industries, or channels.

This model is widely used in **credit risk backtesting, model validation, and regulatory review**.

---

## 🔍 Detection Logic

A loan is flagged when:

1. Borrower type = **SME / small enterprise**;
2. Loan classification transitions to **NPL** (Substandard / Doubtful / Loss);
3. Calculate: days_to_npl = npl_date - origination_date;
4. Flag if:
- `days_to_npl ≤ :EARLY_DEFAULT_DAYS` (e.g., 90 / 180 days)
- OR falls into defined seasoning buckets

---

## 🗂️ Required Tables (Generic)

| Table | Key Fields | Description |
|------|-----------|-------------|
| `loans` | loan_id, customer_id, origination_date, product_category, org_id | Loan master |
| `loan_classification_history` | loan_id, classification, classification_date | Risk migration history |
| `customers` | customer_id, enterprise_size | SME identification |
| `party` | customer_id, customer_name | Borrower info |
| `org_hierarchy` | org_id, level1/2/3 | Branch hierarchy |

---

## ⚙️ Parameters

| Parameter | Description |
|----------|-------------|
| `:REPORT_DATE` | snapshot date |
| `:EARLY_DEFAULT_DAYS` | threshold for early default |
| `:OBS_START_DATE` | loan origination lower bound |
| `:INCLUDE_ONLY_NPL` | Y/N filter only NPL loans |

---

## 📊 Output Fields

- Branch hierarchy (L1–L3)  
- loan_id, customer_id, customer_name  
- origination_date  
- first_npl_date  
- days_to_npl  
- current_classification  
- early_default_flag  

---

## 📝 Notes

- Early defaults (e.g., < 90 days) are strong fraud or underwriting signals.  
- Can be aggregated to build:
- **vintage curves**
- **early default rate (EDR)**
- Very important for **IRB / IFRS9 validation and regulatory inspections**.
