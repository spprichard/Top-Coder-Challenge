# Brainstorming: Reverse-Engineering ACME Corp's Legacy Reimbursement System

## 1. Key Takeaways from PRD.md
- **Goal:** Faithfully replicate the legacy system's output, including quirks and bugs, using only the provided data and interviews.
- **Inputs:**
  - `trip_duration_days` (int)
  - `miles_traveled` (int/float)
  - `total_receipts_amount` (float)
- **Output:** Single float, rounded to 2 decimals, matching legacy system as closely as possible.
- **Knowns:**
  - System is unpredictable, with inconsistent treatment of receipts, trip lengths, and distances.
  - Suspected bugs/quirks must be preserved.
  - Output is not always logical or proportional.
- **Success:** Minimize deviation from legacy outputs on public and private test cases.

## 2. Key Takeaways from INTERVIEWS.md
### General Themes
- **Unpredictability:** Users report inconsistent results for similar trips.
- **Possible Factors:**
  - Calendar/time of month or quarter (some believe more generous at certain times, but evidence is mixed)
  - Trip length: 5-day trips often get a bonus, but not always; 8-day trips sometimes get a big boost
  - Mileage: Tiered rates, not linear; first ~100 miles at a higher rate, then drops, but not a simple formula
  - Receipts: Diminishing returns for high receipts, penalties for very low receipts, possible non-linear or capped treatment
  - Efficiency: Covering more ground in less time may yield bonuses
  - Rounding: If receipts end in .49 or .99, system may round up more generously (possible bug/feature)
  - Occasional randomness or hidden factors (user history, department, etc.)

### Specific Observations
- **Per Diem:** $100/day is a base, but with unexplained adjustments (esp. for 5-day trips)
- **Mileage:**
  - First ~100 miles at full rate (~$0.58/mile), then rate drops, possibly non-linear (maybe logarithmic or stepwise)
  - High-mileage trips sometimes get better per-mile rates than expected
- **Receipts:**
  - Medium-high receipts ($600-800) get best treatment
  - High receipts ($1000+) see diminishing returns
  - Very low receipts can be penalized (sometimes better to submit none)
  - Not strictly proportional; possible cap or curve
- **Edge Cases/Bugs:**
  - Rounding bug for receipts ending in .49 or .99
  - 5-day trip bonus, but not always applied
  - Efficiency bonus for high miles/day, but not strictly miles/days
  - Occasional "magic numbers" (e.g., $847)

## 3. Data Patterns (Initial Glance at public_cases.json)
- **Short trips (1-3 days):** Reimbursement is often much higher than receipts, suggesting a strong per diem/mileage base.
- **5-day trips:** Many have a noticeable jump in reimbursement, supporting the "5-day bonus" theory.
- **High receipts:** Reimbursement does not scale linearly; e.g., $1300 in receipts does not yield $1300+ in reimbursement.
- **Mileage:** High mileage does not always mean high reimbursement; rate per mile drops off after a threshold.
- **Low receipts:** Sometimes penalized, especially for multi-day trips.
- **Rounding:** Many outputs end in .49, .99, or .00, supporting the rounding bug theory.

## 4. Hypotheses for System Logic
- **Base per diem:** $100/day, with a possible bonus for 5-day trips.
- **Mileage:**
  - First 100 miles at $0.58/mile
  - Next 400 miles at $0.40/mile
  - Miles above 500 at $0.25/mile
  - Or, a logarithmic/stepwise curve
- **Receipts:**
  - 80-90% of receipts reimbursed up to a threshold ($600-800), then diminishing returns
  - Penalty for receipts below a certain threshold (e.g., $50 for multi-day trips)
- **Efficiency bonus:** If miles/trip_duration_days exceeds a threshold, add a bonus
- **Rounding bug:** If receipts end in .49 or .99, round up twice or add a small bonus
- **Randomness/hidden factors:** Occasional unexplained variation (simulate with a small random adjustment?)

## 5. Next Steps
- Analyze public_cases.json in detail: plot reimbursement vs. each input, look for breakpoints, clusters, and outliers
- Test above hypotheses with sample calculations
- Build a flexible model to tweak parameters and match outputs
- Pay special attention to 5-day trips, high/low receipts, and rounding edge cases
- Document all findings and logic in this file as you iterate

---

## Deeper Analysis (June 7, 2025)

### 1. Per Diem Logic
- **$100/day base** is strongly supported by interviews and data.
- **5-day trips**: Many public cases show a noticeable jump in reimbursement for 5-day trips, but not always. This suggests a “5-day bonus” that is sometimes suppressed by other factors (e.g., very low receipts, or perhaps a cap).
- **8-day trips**: Sometimes get a big boost, but not always. There may be a secondary bonus or a non-linear effect for longer trips.

### 2. Mileage Logic
- **Tiered rates**: The first ~100 miles are reimbursed at a high rate (about $0.58/mile), then the rate drops. The drop is not linear—sometimes it looks like a step, sometimes a curve.
- **High-mileage trips**: Sometimes get a better per-mile rate than expected, possibly due to an “efficiency” or “distance” bonus, or a bug.
- **Possible model**: 
  - First 100 miles: $0.58/mile
  - Next 400 miles: $0.40/mile
  - Miles above 500: $0.25/mile
  - Or, a logarithmic or stepwise function.

### 3. Receipts Logic
- **Medium-high receipts ($600-800)**: These get the best treatment, often reimbursed at 80-90%.
- **High receipts ($1000+)**: Diminishing returns—each extra dollar is worth less.
- **Very low receipts**: Sometimes penalized, especially for multi-day trips. In some cases, submitting no receipts is better than submitting a small amount.
- **Not strictly proportional**: There’s a cap or curve, and possibly a penalty for “suspiciously” low receipts.

### 4. Efficiency Bonus
- **Miles per day**: Covering a lot of ground in a short time may yield a bonus, but it’s not strictly miles/days. There may be a threshold or a non-linear effect.
- **Edge cases**: Some trips with high miles/day get a bonus, others don’t—suggesting other factors are involved.

### 5. Rounding and Bugs
- **Rounding bug**: If receipts end in .49 or .99, the system may round up twice or add a small bonus. This is supported by both interviews and data (many outputs end in .49, .99, or .00).
- **Magic numbers**: Some outputs (e.g., $847) appear more often than expected, possibly due to a bug or a “lucky” calculation path.
- **Randomness**: There may be a small random adjustment, or hidden factors (e.g., user history, department) that are not in the data.

### 6. Data Patterns
- **Short trips (1-3 days)**: Reimbursement is often much higher than receipts, suggesting a strong per diem/mileage base.
- **5-day trips**: Many have a noticeable jump in reimbursement, supporting the “5-day bonus” theory.
- **High receipts**: Reimbursement does not scale linearly; e.g., $1300 in receipts does not yield $1300+ in reimbursement.
- **Mileage**: High mileage does not always mean high reimbursement; rate per mile drops off after a threshold.
- **Low receipts**: Sometimes penalized, especially for multi-day trips.
- **Rounding**: Many outputs end in .49, .99, or .00, supporting the rounding bug theory.

---

## Data Analysis Summary (June 7, 2025)

### Visual Insights from Plots
- **Reimbursement vs Trip Duration:**
  - Clear stepwise increases, especially at 5 days (supporting the "5-day bonus" hypothesis).
  - Short trips (1-3 days) have a strong per diem effect; reimbursement is much higher than receipts.
  - 8-day trips sometimes show a secondary boost, but not as consistently as 5-day trips.

- **Reimbursement vs Miles Traveled:**
  - Initial steep increase for the first ~100 miles, then a gentler slope, supporting a tiered or diminishing mileage rate.
  - High-mileage trips do not always yield proportionally higher reimbursements, confirming diminishing returns.

- **Reimbursement vs Receipts:**
  - Medium-high receipts ($600-800) cluster at higher reimbursement rates.
  - High receipts ($1000+) show diminishing returns; each extra dollar is worth less.
  - Very low receipts can result in lower-than-expected reimbursements, especially for multi-day trips.

- **5-day and 8-day Trips:**
  - 5-day trips show a distinct cluster with higher reimbursements, confirming a bonus or special treatment.
  - 8-day trips sometimes show a similar effect, but less pronounced.

- **Rounding Bug Analysis:**
  - Receipts ending in .49 or .99 often correspond to reimbursements ending in .49, .99, or .00, supporting the rounding bug theory.
  - These cases sometimes receive a small bonus or upward adjustment.

### Overall Patterns
- The data supports the hypotheses of a base per diem, tiered mileage, diminishing returns on receipts, and special bonuses/quirks for certain trip lengths and receipt endings.
- There are clear non-linearities and edge cases that must be handled to closely match the legacy system.

**Next:** Use these insights to guide the first version of the reimbursement calculation logic, and continue to iterate based on error analysis.
