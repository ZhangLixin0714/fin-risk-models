{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Multiple Second-Hand-Mortgage Payouts to the Same Payee\n",
    "\n",
    "> Detects clusters of loans where many different borrowers send money to the same recipient account — a strong indicator of organized mortgage fraud.\n",
    "\n",
    "## 📌 How it works\n",
    "\n",
    "1. Select second-hand housing loans issued in a time window\n",
    "2. Join with account-level payee data\n",
    "3. Flag payee accounts used by >10 distinct borrowers\n",
    "4. Output all relevant details including borrower name, balance, partner organization, etc.\n",
    "\n",
    "## 📁 Tables used (generic)\n",
    "\n",
    "- `loan_bill` — per-loan facts like lending date, balance\n",
    "- `loan_account` — payee accounts and contract metadata\n",
    "- `partner_org`, `customer_prof`, `project` — dimensions for context\n",
    "\n",
    "## 🎛 Parameters\n",
    "\n",
    "- `:snapshot_date` — report date for current view\n",
    "- `:year_list` — years to include (e.g. 2023–2025)\n",
    "\n",
    "## 📌 Output\n",
    "\n",
    "Includes payee account name, # of borrowers sharing it, and all related business info. Sorted by highest risk first.\n",
    "\n",
    "## 📣 License\n",
    "\n",
    "Apache-2.0 — reuse freely with attribution. Please ⭐️ the main repo if useful!"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3 (ipykernel)",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.11.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
