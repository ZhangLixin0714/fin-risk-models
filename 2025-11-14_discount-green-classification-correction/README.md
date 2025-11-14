# Discount Financing — Artificial Green Classification (CRC Correction Category)

📅 **Date:** 2025-11-14  
📂 **Category:** Green Finance Risk / Regulatory Classification  
🎯 **Use case:** Identify clients whose reported “green” status is not aligned with their actual financing behaviors — especially those using discount financing for non-green purposes.

---

## 🧠 Objective
To detect clients whose **green financing classification** appears artificially enhanced (“绿漂”), particularly when:

- Their discount financing flows do **not** support genuine green activities;  
- Their industry doesn’t qualify for green categories;  
- Their loan/bill usage conflicts with approved green projects;  
- Their green classification has been tagged for **regulatory correction (CRC)**.

This model provides a **portfolio-level scan** for clients requiring review or downgrading of their green classification.

---

## 🔍 Detection Logic

1. **Identify clients labeled as “green”** in regulatory or internal green-finance systems.  
2. Match customer financing behaviors, including:  
   - Discounted bills  
   - Working capital loans  
   - Trade financing  
   - Short-term liquidity borrowings  
3. Flag cases where:
   - Financing proceeds do **not** match green project scope;  
   - Optical green categories (e.g., low-carbon logistics, generic service providers) are used improperly;  
   - Discount flows route into **non-green activities**;  
   - Historical classification mismatches exist (CRC list).  
4. Compute indicators:
   - `% of financing supporting non-green activities`  
   - `green usage consistency ratio`  
   - `CRC_flag`  
   - Count of mismatches across product types.  
5. Output CRC candidates for:
   - re-validation  
   - downgrade  
   - rectification reporting  
   - regulatory audit preparation

---

## 🗂️ Required Tables (Generic)

| Table | Key Fields | Description |
|-------|------------|-------------|
| `customer_green_class` | party_id, green_category, crc_flag | Internal green classification registry |
| `discount_bills` | party_id, bill_id, use_of_proceeds, issue_date, maturity_date, amount | Discount financing behaviors |
| `loans` | party_id, loan_id, product_category, use_of_funds, origination_date, amount | Loan-level purpose + flow |
| `industry_catalog` | industry_code, green_eligible_flag | Industry green eligibility |
| `org_hierarchy` | org_id, level1/2/3 | Branch labels |
| `party` | party_id, party_name, industry_code | Client registry |

---

## ⚙️ Parameters

| Parameter | Description |
|------------|-------------|
| `:REPORT_DATE` | snapshot date |
| `:OBS_START_DATE` | analysis window start |
| `:GREEN_MISMATCH_THRESHOLD` | mismatch rate above which clients are flagged |
| `:NONGREEN_FLOW_THRESHOLD` | absolute non-green flow threshold |
| `:CRC_ONLY_FLAG` | restrict to CRC-tagged clients only (Y/N) |

---

## 📤 Output Fields

- Branch hierarchy (L1–L3)  
- party_id, party_name  
- industry_code, industry_green_eligible  
- green_class, crc_flag  
- total_financing_amt  
- non_green_flow_amt  
- mismatch_rate  
- risk_label

---

## 📝 Notes

- Use standardized “use of funds” mapping to classify flows as green/non-green.  
- Cross-verify discount-bill activities with green project scope.  
- Ideal for **green finance audit**, regulatory assessments, and portfolio reclassification.
