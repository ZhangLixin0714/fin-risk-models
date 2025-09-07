# Personal Business Loan — First-Year Delinquency After Origination

📅 **Date:** 2025-09-07  
📂 **Category:** Personal Business / Sole-Proprietor Lending Risk  
🎯 **Use case:** Identify underwriting weaknesses and early stress via first-year delinquency monitoring.

---

## 🧠 Objective
Flag personal business loans that become **delinquent within the first year after origination**, signaling potential misrepresentation, weak borrower capacity, or channel risk.

---

## 🔍 Detection Logic
- Cohort = personal business loans originated within an observation window.  
- Flag if **first delinquency** occurs within `:DAYS_LIMIT` (default 365 days).  
- Delinquency = `days_past_due ≥ :DELQ_DPD_THRESHOLD` (default 30 DPD) or risk class in an adverse set (Special Mention / Substandard / Doubtful / Loss).  

---

## 🗄️ Required Tables
- `loans`  
- `loan_status_events` (preferred) or `loan_daily_snapshots`  
- `org_hierarchy` (for branch labels)  
- `product_catalog` (for product names)

---

## ⚙️ Parameters
- `:REPORT_DATE` — snapshot date  
- `:OBS_START_DATE` — lower bound for origination cohort  
- `:DAYS_LIMIT` (default 365) — “first-year” window  
- `:DELQ_DPD_THRESHOLD` (default 30) — delinquency threshold  
- `:ADVERSE_RISK_CLASSES` — e.g., `{SpecialMention, Substandard, Doubtful, Loss}`

---

## 📊 Output
- Branch hierarchy (level1, level2, level3)  
- Loan & product metadata  
- Origination and delinquency dates  
- `days_to_first_delq`  
- `first_year_delq_flag`

---

## 📝 Extensions
- Snapshot KPI: first-year delinquency rate by org & product.  
- Exclude technical arrears (e.g., delinquency < 7 days).  
- Add stratification: ticket size, channel, or FPD (first-payment default).

---

⭐ If you use this model, please star or cite the repo to support open-source financial risk analytics.
