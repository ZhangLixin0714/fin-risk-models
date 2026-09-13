# Credit Operations Alerts — Overdue Investigation Response Monitoring

**Date:** 2026-09-13  
**Category:** SME Credit Operations / Internal Controls / Exception Monitoring  
**Use case:** Identify credit-operation monitoring alerts for SME borrowers where the investigation or response process exceeds the required turnaround time.

---

## Objective

This model identifies overdue investigation and response items generated through credit-operation monitoring processes.

The model focuses on SME borrowers with active credit exposure and compares:

- the date on which a monitoring event was generated;
- the most recent processing or modification date; and
- the required number of days for investigation feedback.

An item is flagged when:

`actual_response_days > required_response_days`

The resulting exception population can support operational-risk monitoring, internal control testing, management escalation, and remediation tracking.

---

## Detection Logic

### Step 1 — Define the eligible SME borrower population

Select SME borrowers that:

- meet the configured SME classification criteria;
- have outstanding loan exposure at the reporting date;
- have aggregate contract exposure below the configured portfolio threshold.

The original monitoring logic uses a total contract amount threshold of **10,000,000**.

### Step 2 — Confirm active loan exposure

Retain customers with active loan principal balances at the reporting date.

### Step 3 — Retrieve credit-operation monitoring events

Retrieve monitoring or warning records generated during the observation period from the relevant credit-operation monitoring sources.

For each event, capture:

- monitoring alert ID;
- event date;
- last modification date;
- required response period;
- investigation-required indicator.

### Step 4 — Calculate response delay

Calculate:

`actual_response_days = last_modified_date - event_date`

An event is overdue when:

`actual_response_days > required_response_days`

### Step 5 — Consolidate monitoring sources

Combine qualifying exception records from the applicable monitoring-event sources into one review population.

---

## Required Data

| Dataset | Key Fields | Purpose |
|---|---|---|
| `corporate_loan_contract_summary` | customer_id, contract_amount, loan_balance, snapshot_date | Defines borrower exposure and aggregate contract amount |
| `corporate_customer_master` | customer_id, customer_name, sme_flag | Identifies SME borrowers |
| `corporate_loan_accounts` | customer_id, principal_balance, org_id | Confirms active loan exposure |
| `org_hierarchy` | org_id, branch_name, subbranch_name, outlet_name | Organization labels |
| `credit_monitoring_alert_history` | customer_id, alert_id, event_date, last_modified_date, required_response_days, investigation_required | Monitoring alert records |
| `credit_monitoring_case_history` | customer_id, alert_id, event_date, last_modified_date, required_response_days, investigation_required | Additional monitoring/case records |

---

## Parameters

| Parameter | Description | Example |
|---|---|---:|
| `:OBS_START_DATE` | Start of event observation period | `2026-01-01` |
| `:REPORT_DATE` | Reporting / snapshot date | `2026-09-13` |
| `:MAX_TOTAL_CONTRACT_AMT` | Maximum aggregate contract exposure | `10000000` |

---

## Output Fields

- `level1_branch`
- `subbranch`
- `outlet_name`
- `customer_id`
- `customer_name`
- `alert_id`
- `event_date`
- `last_modified_date`
- `required_response_days`
- `actual_response_days`
- `overdue_days`
- `investigation_required`
- `alert_source`
- `timeliness_flag`

---

## Risk Interpretation

A flagged case indicates that the recorded handling period exceeded the required response period.

It does **not necessarily mean that the underlying credit risk itself has deteriorated**. Instead, it is primarily an operational and control-timeliness indicator.

Potential implications include:

- delayed investigation of credit warning signals;
- weak monitoring discipline;
- insufficient case-management capacity;
- delayed escalation of borrower risk;
- inconsistent execution of post-loan monitoring procedures.

---

## Potential Extensions

This model can be extended to measure:

1. Average overdue days by branch;
2. Percentage of alerts completed within SLA;
3. Repeated overdue investigations for the same borrower;
4. High-risk cases that remain unresolved beyond multiple SLA periods;
5. Overdue investigation rates by relationship manager or operating unit;
6. Relationship between investigation delays and subsequent credit deterioration.

---

## Disclaimer

This repository contains generalized financial risk-monitoring logic for research and educational purposes. Table names, field names, customer classifications, internal workflow codes, thresholds, and implementation details are illustrative and should be adapted to the user's own data environment.
