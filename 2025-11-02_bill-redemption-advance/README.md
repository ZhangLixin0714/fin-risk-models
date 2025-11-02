# Trade Bill Redemption — Advance Payment Detection

📅 **Date:** 2025-11-02  
📂 **Category:** Trade Bill Risk / Liquidity Management  
🎯 **Use case:** Detect cases where a bank or related entity **advances funds** to cover a company’s maturing trade bill before the drawer’s actual repayment, indicating hidden rollover or implicit guarantee behavior.

---

## 🧠 Objective
Identify enterprises whose trade bills are redeemed not by the original drawer but by **temporary bridge financing** or **bank advance payments**.  
Such patterns may imply concealed default, internal fund recycling, or disguised non-performing assets.

---

## 🔍 Detection Logic
1. Retrieve all **trade bills reaching maturity** during the observation window.  
2. Check **redemption source** and **payment timing**:  
   - Redemption fund does **not** originate from the drawer’s settlement account;  
   - Payment occurs **within :ADVANCE_WINDOW_DAYS** before actual maturity;  
   - Fund source account belongs to the same group / branch or a known funding intermediary.  
3. Compute and classify:  
   - Redemption ratio = advanced payments / total bill redemption amount;  
   - Frequency of advance behavior per customer and per branch.  
4. Flag when redemption ratio ≥ `:ADVANCE_RATIO_LIMIT` or repeated events ≥ `:FREQUENCY_LIMIT`.

---

## 🗂️ Expected Tables
| Table | Key Columns | Description |
|-------|--------------|-------------|
| `trade_bills` | bill_id, drawer_party_id, payee_party_id, bill_maturity_date, bill_amount, redemption_date, redemption_source_acct_id | Core bill data |
| `accounts` | acct_id, party_id, acct_type | Account ownership mapping |
| `org_hierarchy` | org_id, level1_name, level2_name, level3_name | Branch hierarchy |
| `party` | party_id, party_name, group_id | Customer registry |

---

## ⚙️ Parameters
| Parameter | Description | Example |
|------------|--------------|----------|
| `:REPORT_DATE` | snapshot date | `'2025-11-02'` |
| `:OBS_START_DATE` | window start | `'2025-10-01'` |
| `:ADVANCE_WINDOW_DAYS` | days before maturity to consider “advance” | `7` |
| `:ADVANCE_RATIO_LIMIT` | advance redemption ratio threshold | `0.3` |
| `:FREQUENCY_LIMIT` | event frequency threshold | `2` |

---

## 📊 Output
- branch hierarchy (L1–L3)  
- drawer_party_id, drawer_name, group_id  
- bill_count, total_bill_amount, advanced_redeem_amount, advance_ratio  
- redemption_dates (min/max)  
- event_frequency, risk_flag  

---

## 📝 Notes
- Cross-check redemption source accounts with drawer accounts to confirm mismatch.  
- Optionally tag internal transfers (same bank) as **medium-risk** and external third-party advances as **high-risk**.  
- Useful KPI: proportion of “advance-redeemed” bills in total matured bills per branch or group.
