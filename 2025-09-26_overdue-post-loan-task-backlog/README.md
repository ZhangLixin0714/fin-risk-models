# Personal Loans — Overdue Post-Loan Task Backlog

**Date:** 2025-09-26  
**Category:** Post-loan operations risk  
**Scope:** Branch / officer aggregation  
**Use case:** Surface branches/officers with sustained backlogs of overdue post-loan tasks (missing document collection, contact checks, collateral re-verification, etc.), which correlates with weak controls and future delinquency.

---

## 🎯 Objective
Flag branches/officers where the share or count of **overdue** post-loan tasks breaches thresholds for ≥N consecutive days (or within a rolling window).

---

## 🧠 Detection Logic (summary)
1. Take post-loan tasks tied to **personal loans**.
2. A task is **overdue** if `due_date < snapshot_date` and `completed_at IS NULL` (or completed after due date).
3. Aggregate by **branch** and **loan_officer** over a lookback window (e.g., last 14 days).
4. Alert if:
   - `overdue_rate ≥ :overdue_rate_threshold` **or** `overdue_cnt ≥ :overdue_cnt_threshold`
   - and backlog persists on **≥ :min_persist_days** within the window.

---

## 🗂️ Tables (expected)
- `post_loan_task` — task_id, loan_id, branch_id, officer_id, task_type, due_date, completed_at, created_at
- `loan` — loan_id, product = 'PERSONAL', booked_branch_id, officer_id, disbursed_at, status
- `branch` — branch_id, branch_name, region
- `officer` — officer_id, officer_name

---

## ⚙️ Parameters
- `:snapshot_date` — e.g. `DATE '2025-09-26'`
- `:lookback_days` — e.g. `14`
- `:overdue_rate_threshold` — e.g. `0.30`
- `:overdue_cnt_threshold` — e.g. `50`
- `:min_persist_days` — e.g. `3`

---

## 📤 Output Columns
- snapshot_date, branch_id, branch_name, officer_id, officer_name  
- overdue_cnt, task_cnt, overdue_rate, persist_days  
- sample_loan_ids (optional), top_task_types (optional)

---

## 📝 Notes
- Tune thresholds by portfolio size—big branches may trip `overdue_cnt`, small ones `overdue_rate`.
- Consider excluding tasks created within the last X days to avoid “fresh-but-not-due” noise.
