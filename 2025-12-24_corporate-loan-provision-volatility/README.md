# Corporate Loan — Notes with Significant Provision Fluctuations

📅 **Date:** 2025-12-24  
📂 **Category:** Corporate Credit Risk / Provisioning & Accounting  
🎯 **Use case:** Identify corporate loan notes where **loan loss provisions change significantly** over a short period, indicating potential risk reclassification, earnings management, or delayed risk recognition.

---

## 🧠 Objective
Detect corporate loan notes exhibiting **abnormal fluctuations in credit loss provisions**, which may signal:

- Rapid deterioration or improvement in borrower credit quality;
- Inconsistent risk classification or delayed recognition of impairment;
- Earnings smoothing or provisioning volatility;
- Heightened regulatory and audit attention.

This model supports **asset quality review, accounting consistency checks, and supervisory inspections**.

---

## 🔍 Detection Logic

A loan note is flagged if **any** of the following conditions are met:

1. Absolute provision change exceeds `:ABS_CHANGE_THRESHOLD`;  
2. Relative provision change exceeds `:REL_CHANGE_THRESHOLD`;  
3. Provision ratio (provision / outstanding balance) jumps across risk buckets;  
4. Provision change is not aligned with corresponding changes in:
   - days past due,
   - risk classification,
   - restructuring or forbearance status.

Optional segmentation:
- By branch;
- By industry;
- By loan officer or portfolio.

---

## 🗂️ Required Tables (Generic)

| Table | Key Fields | Description |
|------|-----------|-------------|
| `loan_notes` | note_id, loan_id, customer_id, outstanding_balance, org_id | Loan note granularity |
| `loan_provisions` | note_id, provision_date, provision_amount | Provision history |
| `loans` | loan_id, risk_class, days_past_due, restructuring_flag | Loan master |
| `party` | customer_id, customer_name, industry_code | Borrower registry |
| `org_hierarchy` | org_id, level1/2/3 | Branch hierarchy |

---

## ⚙️ Parameters

| Parameter | Description |
|----------|-------------|
| `:REPORT_DATE` | snapshot date |
| `:PREV_DATE` | comparison date |
| `:ABS_CHANGE_THRESHOLD` | absolute provision change threshold |
| `:REL_CHANGE_THRESHOLD` | relative provision change threshold |
| `:MIN_BALANCE` | minimum outstanding balance |
| `:INCLUDE_WRITE_OFF` | Y/N include written-off notes |

---

## 📤 Output Fields

- Branch hierarchy (L1–L3)  
- note_id, loan_id  
- customer_id, customer_name  
- outstanding_balance  
- provision_prev, provision_curr  
- provision_change_amt  
- provision_change_pct  
- risk_class, days_past_due  
- risk_flag

---

## 📝 Notes

- Sudden provision drops deserve as much attention as sharp increases.  
- Combine with migration matrices for deeper analysis.  
- Useful KPI: % of corporate loan balance with high provision volatility.
