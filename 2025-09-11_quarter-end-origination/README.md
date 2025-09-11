# Personal Loan — Quarter-End Origination & Early Next-Quarter Payoff

📅 **Date:** 2025-09-11  
📂 **Category:** Retail Lending / Consumer Loan Risk  
🎯 **Use case:** Detect quarter-end “window dressing” or round-trip lending.

---

## 🧠 Objective
Flag loans that are:
- **Originated** in the final days of a fiscal quarter, and  
- **Paid off** (fully closed) within the opening days of the next quarter,  
with short **days_to_payoff** and above a minimum ticket size.

Such patterns often indicate quarter-end volume boosting or partner-driven recycling.

---

## 🔍 Detection Logic
- Origination window: last `:ORIG_WINDOW_DAYS` of quarter (default 7)  
- Payoff window: first `:PAYOFF_WINDOW_DAYS` of next quarter (default 14)  
- Signal: loans with `days_to_payoff` between 1 and `:MAX_DAYS_TO_PAYOFF` (default 60)  
- Principal filter: `original_principal >= :MIN_ORIG_AMT` (default 50,000)

---

## 🗄️ Required Tables
- `loans` — loan metadata, origination & close_date  
- `loan_status_events` or `loan_daily_snapshots` — to infer payoff date if close_date missing  
- `org_hierarchy` — branch labels  
- `product_catalog` — product names

---

## ⚙️ Parameters
- `:REPORT_DATE` — snapshot as-of date  
- `:OBS_START_DATE` — origination cohort lower bound  
- `:ORIG_WINDOW_DAYS` (default 7)  
- `:PAYOFF_WINDOW_DAYS` (default 14)  
- `:MAX_DAYS_TO_PAYOFF` (default 60)  
- `:MIN_ORIG_AMT` (default 50,000)

---

## 📊 Output
- Org hierarchy (branch path)  
- Loan + customer identifiers  
- Origination date, payoff date  
- Days_to_payoff  
- Ticket size  

---

## 📝 Governance
- Tighten windows for stricter detection (e.g., 3–5 days end-of-quarter, 7 days next-quarter).  
- Exclude operational reversals or refinances within same family.  
- Review flagged cases for sales incentive or partner program effects.

---
