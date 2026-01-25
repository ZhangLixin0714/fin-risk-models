# SME Borrowers (Non-NPL) with External Fraud Events

📅 **Date:** 2026-01-25  
📂 **Category:** SME Credit Risk / Early Warning Signals  
🎯 **Use case:** Identify **non-NPL SME borrowers** who are involved in external fraud-related events such as dishonesty records, lawsuits, or enforcement actions, indicating elevated latent credit risk.

---

## 🧠 Objective
Detect early warning signals among **performing SME borrowers** whose internal loan status remains normal, but who exhibit **external adverse events**, including:

- Dishonesty / default listings;
- Civil or commercial litigation;
- Enforcement actions or judicial restrictions;
- Administrative penalties or credit blacklists.

This model helps bridge the gap between **internal asset classification** and **external risk reality**.

---

## 🔍 Detection Logic

A borrower is flagged if **all conditions below are met**:

1. Borrower type = **SME**;
2. Current loan classification ≠ NPL (e.g., Normal / Special Mention);
3. One or more **external risk events** are identified within the observation window:
   - dishonesty / default registry,
   - lawsuit involvement,
   - enforcement or judgment records,
   - other public fraud-related disclosures;
4. External event date ≥ `:OBS_START_DATE`.

Optional prioritization:
- High-impact legal cases;
- Repeated events;
- Events involving actual controllers or affiliates.

---

## 🗂️ Required Tables (Generic)

| Table | Key Fields | Description |
|------|-----------|-------------|
| `loans` | loan_id, customer_id, product_category, risk_class, current_balance | Loan master |
| `customers` | customer_id, customer_type, enterprise_size | Borrower profile |
| `external_risk_events` | customer_id, event_type, event_date, event_severity | External risk registry |
| `party` | customer_id, customer_name | Borrower identity |
| `org_hierarchy` | org_id, level1/2/3 | Branch hierarchy |

---

## ⚙️ Parameters

| Parameter | Description |
|----------|-------------|
| `:REPORT_DATE` | snapshot date |
| `:OBS_START_DATE` | external event observation window |
| `:EXCLUDE_NPL` | Y/N exclude NPL borrowers |
| `:MIN_EVENT_SEVERITY` | minimum external event severity |

---

## 📤 Output Fields

- Branch hierarchy (L1–L3)  
- customer_id, customer_name  
- loan_id  
- current_balance  
- internal_risk_class  
- external_event_type  
- external_event_date  
- external_event_severity  
- warning_flag

---

## 📝 Notes

- This is a **pre-default risk identification** model.  
- External risk does not imply immediate default but warrants enhanced monitoring.  
- Suitable for **post-loan management**, **regulatory stress testing**, and **portfolio early-warning dashboards**.
