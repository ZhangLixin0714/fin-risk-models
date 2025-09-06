# Employee Self-Involvement in Own Loan Workflow

**📅 Date:** 2025-09-06  
**📂 Category:** Employee Conflict-of-Interest Monitoring  
**🌍 Scope:** Workflow events on employee loans  
**🎯 Use case:** Detecting conflicts of interest when employees act on their own loans

---

## 🧠 Objective
Flag cases where employees perform **workflow actions** (initiation, approval, disbursement, restructuring, etc.) on loans where they themselves are the borrower (mapped through their personal customer profile).

---

## 🔍 Detection Logic
- Join **loan_workflow_events** with **staff_customer_map** to map employee staff IDs ↔ their retail customer IDs.  
- Flag events where `actor_staff_id` belongs to the **same person** as `loan.primary_borrower_customer_id`.  
- Apply filters: exclude service accounts, drop view-only events, optionally restrict to high-risk actions.  
- Severity scale:
  - **High** → self-approval/disbursement
  - **Medium** → participation in application/doc checks
  - **Low** → incidental workflow events

---

## 🗄️ Required Tables
- `loans`
- `loan_workflow_events`
- `staff_directory`
- `staff_customer_map`
- `org_hierarchy`
- `product_catalog`

---

## ⚙️ Parameters
- `:REPORT_DATE` — as-of reference date  
- `:OBS_START_DATE`, `:OBS_END_DATE` — event observation window  
- `:RISK_ACTIONS` — optional list of actions (e.g., `{APPROVAL, DISBURSEMENT}`)  
- `:EXCLUDE_SERVICE_ACCOUNTS` — default true  
- `:EXCLUDE_VIEW_ONLY` — default true  

---

## 📊 Output
- Org path: branch hierarchy  
- Loan metadata: product, balance, origination date  
- Event metadata: timestamp, event type, actor staff ID, role, channel  
- Derived field: **severity**

---

## 📈 Extensions
- Add **related-party detection** (employee relatives).  
- Add **device/IP checks** for same-device activity.  
- KPI: self-involvement cases per 1,000 loans; severity mix; time-to-remediation.  

---
