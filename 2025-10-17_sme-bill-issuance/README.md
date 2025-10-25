# SME Trade Bill Issuance — Monitoring Model

📅 **Date:** 2025-10-17  
📂 **Category:** Small Business Credit / Short-term Financing  
🎯 **Use case:** Detect small- and micro-enterprise clients that rely heavily on **trade bill issuance** (banker’s acceptances or commercial bills), signaling potential liquidity stress or disguised borrowing.

---

## 🧠 Objective
Analyze issuance activity of **small and micro enterprises (SMEs)** within a defined observation period to:
- Identify clients issuing unusually large or frequent bills relative to their credit lines;
- Flag entities that may be using bills as a substitute for direct loans;
- Support branch-level early-warning and risk concentration monitoring.

---

## 🔍 Detection Logic
1. Extract all trade bills issued by SME clients within the observation window.  
2. Aggregate by company / branch / industry.  
3. Compute metrics:  
   - `total_bill_amount`, `bill_count`, `avg_tenor_days`  
   - `bill_to_loan_ratio` = total_bill_amount / total_loans  
   - `yoy_growth` vs. previous period  
4. Flag if:  
   - `bill_to_loan_ratio` > `:RATIO_LIMIT`, or  
   - `growth_rate` > `:GROWTH_THRESHOLD`, or  
   - `total_bill_amount` > `:AMOUNT_LIMIT`.

---

## 🗂️ Expected Tables

| Table | Key Columns | Description |
|-------|--------------|--------------|
| `trade_bills` | bill_id, drawer_party_id, bill_issue_date, bill_maturity_date, bill_amount, currency_code, issuing_org_id | Bill register |
| `party` | party_id, party_name, enterprise_scale | Used to identify SMEs |
| `loans` | party_id, current_balance, product_category | Outstanding loan data |
| `org_hierarchy` | org_id, level1_name, level2_name, level3_name | Branch structure |

---

## ⚙️ Parameters

| Parameter | Description | Example |
|------------|--------------|----------|
| `:REPORT_DATE` | snapshot date | `'2025-10-17'` |
| `:OBS_START_DATE` | observation start | `'2025-07-01'` |
| `:RATIO_LIMIT` | bill-to-loan ratio threshold | `0.4` |
| `:GROWTH_THRESHOLD` | YoY or MoM growth threshold | `0.3` |
| `:AMOUNT_LIMIT` | absolute total amount flag | `10,000,000` |

---

## 📊 Output Fields
- branch hierarchy (L1–L3)  
- party_id, party_name, enterprise_scale  
- bill_count, total_bill_amount, avg_tenor_days  
- loan_balance, bill_to_loan_ratio  
- growth_rate, risk_flag  

---

## 📝 Notes
- SMEs determined by `enterprise_scale` or regulatory size classification.  
- Exclude non-corporate entities and related-party transactions.  
- Add group-level aggregation for controlling group monitoring.  
