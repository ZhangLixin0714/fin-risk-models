# Mortgage — Large Card Installment in the 90 Days Pre-Disbursement

**Date:** 2025-09-17  
**Category:** Mortgage pre-funding risk  
**Scope:** Portfolio/branch level  
**Use case:** Flag borrowers who opened/posted a sizable credit-card installment within *N* days before mortgage interest starts (or first disbursement) — a signal of hidden liabilities / cash-flow stress.

---

## 🧠 Objective
Detect recent leverage spikes or disguised down-payment financing by searching for card-installment agreements in the lookback window before `start_interest_date`.

## 🗂️ Data (logical)
- `loan_accounts` (mortgage loans with `start_interest_date`, `product_category`)
- `loan_disbursements` (optional for context)
- `org_hierarchy` (branch names)
- `product_catalog`
- `card_installments` (customer, `effect_date`, `installment_amount`)

## ⚙️ Parameters
- `:REPORT_DATE` (DATE)
- `:OBS_START_DATE` (DATE, optional)
- `:LOOKBACK_DAYS` (INT, default **90**)
- `:MIN_INSTALLMENT_AMT` (DECIMAL, default **10000.00**)

## 📄 Files
- **`pre_disbursement_card_installment.sql`** — portable SQL (PostgreSQL style)

## ▶️ How to run
Bind the four parameters and execute `pre_disbursement_card_installment.sql`. Start with `LOOKBACK_DAYS=90`, `MIN_INSTALLMENT_AMT=10000.00`, then calibrate by product tier/region.

## 🚦Tuning & Governance
- Start with the medium-risk baseline (any installment in window).  
- Consider **High risk** if sum of pre-window installments ≥ 3× monthly payment or any single installment ≥ 5% of mortgage amount.  
- Add merchant category filters to reduce durable-goods false positives.

*Model spec and full SQL derived from today’s rule sheet.* 
