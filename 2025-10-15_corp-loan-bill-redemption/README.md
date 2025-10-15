# Corporate Loans Used to Settle the Company’s Own Maturing Trade Bills

**Date:** 2025-10-15  
**Category:** Corporate lending – proceeds tracing  
**Use case:** Identify corporate loans that appear to be raised **to redeem the same company’s maturing trade bills** (e.g., banker's acceptances) within a short window around bill maturity.

---

## 🎯 Objective
Flag cases where a corporate loan’s start-interest (or disbursement) date falls within **N days** before a **bill maturity date** for the **same company (drawer)**, and the **loan amount ≈ bill amount** within a tolerance. This indicates liquidity recycling or reliance on short-term paper.

---

## 🔍 Detection Logic
1. Take **corporate loans** (`product_category='CORP_LOAN'`) active on/after an observation start.  
2. Join to **trade bills** the company has drawn (same legal entity / standardized party name).  
3. Keep pairs where:  
   - `loan_start_date BETWEEN bill_maturity_date - :WINDOW_DAYS AND bill_maturity_date`  
   - `ABS(loan_amount - bill_amount) / GREATEST(loan_amount, bill_amount) ≤ :AMOUNT_TOL_PCT`  
   - (Optional) `currency_code = :CURRENCY`  
4. Enrich with **branch/org** and **standardized party names** for reporting.

---

## 🗂️ Expected Tables (generic)
- `loans` (loan_id, party_id, product_category, start_interest_date, original_principal, currency_code, org_id, open_date)
- `loan_disbursements` (loan_id, disbursement_date, disbursement_amount) *(optional context)*
- `trade_bills` (bill_id, drawer_party_id, bill_amount, bill_maturity_date, drawer_open_bank_id)
- `party` (party_id, party_name)
- `org_hierarchy` (org_id, level1_name, level2_name, level3_name)
- `product_catalog` (product_code, product_name)

---

## ⚙️ Parameters
- `:REPORT_DATE` — snapshot/as-of date  
- `:OBS_START_DATE` — include loans from this date forward  
- `:WINDOW_DAYS` — lookback from maturity (e.g., 3–7 days)  
- `:AMOUNT_TOL_PCT` — amount tolerance (e.g., 0.02 = 2%)  
- `:CURRENCY` — optional currency code (e.g., `CNY`)

---

## 📤 Output (suggested)
- Branch path (level1/2/3), loan_id, party_name, product_name  
- Loan start date, (optional) disbursement date/amount  
- Bill maturity date, bill amount  
- `amount_diff`, `amount_diff_pct`, `window_match_flag`

---

## 📝 Notes
- Standardize names (`party_name`) before joining (or join by `party_id`).  
- Tighten `:WINDOW_DAYS` and `:AMOUNT_TOL_PCT` for stricter signals.  
- Useful KPI: **% of corporate loans likely used for bill redemption** by branch/industry.
