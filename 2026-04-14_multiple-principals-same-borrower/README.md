# Entrusted Loans — Multiple Different Principals Funding the Same Borrower

📅 **Date:** 2026-04-14  
📂 **Category:** Corporate / Entrusted Loan Risk  
🎯 **Use case:** Detect cases where entrusted loan funds from **multiple different principals** ultimately correspond to the **same borrower**, indicating hidden concentration, look-through exposure aggregation, or structured funding behavior.

---

## 🧠 Objective

Identify borrowers that receive entrusted loan funding from **more than one principal** within a defined observation period.  
This helps detect:

- hidden borrower concentration,
- fragmented exposure across multiple principals,
- potential related-party structuring,
- disguised refinancing or channeling behavior.

---

## 🔍 Detection Logic

A borrower is flagged when:

1. The product type is **entrusted loan**;
2. Loan records show **different principal parties**;
3. Those principals' entrusted funds correspond to the **same borrower**;
4. The count of distinct principals exceeds a configurable threshold.

Optional enhancements:
- Aggregate total entrusted balance by borrower;
- Compare borrower concentration across branches;
- Detect whether principals belong to the same corporate group;
- Add time-window clustering (e.g. multiple principals within 30/90 days).

---

## 🗂️ Required Tables (Generic)

| Table | Key Fields | Description |
|------|-----------|-------------|
| `entrusted_loans` | loan_id, borrower_id, principal_id, origination_date, current_balance, product_category, org_id | Entrusted loan-level data |
| `party` | party_id, party_name, party_type, group_id | Borrower / principal registry |
| `org_hierarchy` | org_id, level1_name, level2_name, level3_name | Branch hierarchy |
| `loan_status` | loan_id, risk_class, loan_status | Optional loan status details |

---

## ⚙️ Parameters

| Parameter | Description |
|----------|-------------|
| `:REPORT_DATE` | snapshot date |
| `:OBS_START_DATE` | lower bound for loan origination / observation |
| `:MIN_PRINCIPAL_COUNT` | minimum number of distinct principals to flag |
| `:MIN_TOTAL_BALANCE` | minimum total entrusted balance per borrower |
| `:INCLUDE_CLOSED` | Y/N include closed loans |

---

## 📤 Output Fields

- Branch hierarchy (L1–L3)  
- borrower_id, borrower_name  
- distinct_principal_count  
- principal_list  
- entrusted_loan_count  
- total_balance  
- earliest_origination_date  
- latest_origination_date  
- warning_flag

---

## 📝 Notes

- This is a **look-through concentration model**.  
- Multiple principals funding one borrower may be legitimate, but should be reviewed for risk aggregation and transparency.  
- Particularly useful for entrusted-loan portfolio reviews, related-party screening, and regulatory inspection preparation.
