# Corporate Trade Bill Issuance — Full-Portfolio Monitoring

📅 **Date:** 2025-10-16  
📂 **Category:** Corporate credit / liquidity monitoring  
🎯 **Use case:** Identify companies with high or abnormal levels of **trade bill issuance** (bankers’ acceptances / commercial bills), either relative to their loan size or historical behavior.

---

## 🧠 Objective
Monitor the issuance volume, frequency, and concentration of corporate trade bills to:
- Detect excessive short-term paper financing;
- Identify potential liquidity substitution for regular loans;
- Provide early warning of clients or groups with rapidly expanding paper exposure.

---

## 🔍 Detection Logic
1. Collect **all trade bills issued** within the observation window (e.g., last quarter or year).
2. Aggregate by **company**, **industry**, **region**, and **bank branch**.
3. Calculate:
   - Total issued amount (`SUM(bill_amount)`)
   - Average bill tenor (`AVG(days_to_maturity)`)
   - Number of bills
   - Ratio to company’s total loan balance (`bill_amount / total_loans`)
4. Flag entities where:
   - Bill issuance growth rate exceeds a threshold; or
   - Ratio to loans exceeds `:RATIO_LIMIT`; or
   - Amount concentration within group > `:GROUP_CONCENTRATION_LIMIT`.

---

## 🗂️ Expected Tables
| Table | Key Columns | Description |
|-------|--------------|--------------|
| `trade_bills` | bill_id, drawer_party_id, bill_issue_date, bill_maturity_date, bill_amount, currency_code, issuing_org_id | Core trade bill register |
| `party` | party_id, party_name, industry_code, region_code | Company master |
| `loans` | party_id, product_category, current_balance, org_id | Outstanding loan balances |
| `org_hierarchy` | org_id, level1_name, level2_name, level3_name | Branch hierarchy |

---

## ⚙️ Parameters
| Parameter | Description | Example |
|------------|--------------|----------|
| `:REPORT_DATE` | snapshot date | `'2025-10-16'` |
| `:OBS_START_DATE` | start date for observation window | `'2025-01-01'` |
| `:RATIO_LIMIT` | bill-to-loan ratio threshold | `0.3` |
| `:GROUP_CONCENTRATION_LIMIT` | top-group share threshold | `0.5` |

---

## 📊 Output Fields
- `branch_path (L1–L3)`
- `party_id`, `party_name`, `industry_code`, `region_code`
- `issued_bill_count`, `total_bill_amount`
- `avg_tenor_days`
- `loan_balance`
- `bill_to_loan_ratio`
- `growth_rate_vs_prev_period`
- `risk_flag`

---

## 📝 Notes
- Normalize party names for cross-branch aggregation.  
- Consider filtering only **active corporate clients**.  
- Useful KPIs: total bills issued by region, average tenor trend, bill-to-loan ratio percentile.  
