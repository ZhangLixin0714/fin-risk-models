# Multiple Second-Hand Mortgage Payouts to the Same Payee

📅 **Date**: 2025-07-29

**Description**: Detects clusters of loans where multiple borrowers send funds to the same payee account — a strong indicator of coordinated mortgage fraud.

## 💡 How it works

1. Select second-hand housing loans issued in a given window.
2. Join with account-level payee metadata.
3. Flag payee accounts receiving funds from >10 distinct borrowers.
4. Output relevant data including borrower name, partner org, project, balance, etc.

## 📊 Tables used

- `loan_bill`: Per-loan details (lending date, balance)
- `loan_account`: Payee info and contract metadata
- `partner_org`, `project`, `customer_prof`: Dimensions for filtering
