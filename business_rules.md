# ACME Corp Legacy Reimbursement System Business Rules

## Overview
Based on the PRD, employee interviews, and analysis of the public test cases, the following business rules have been extracted for the 60-year-old legacy travel reimbursement system at ACME Corp.

## Input Parameters
The system accepts three parameters:
- `trip_duration_days` (integer): Number of days spent traveling
- `miles_traveled` (integer): Total miles traveled during the trip
- `total_receipts_amount` (float): Total dollar amount of submitted receipts

## Core Business Rules

### 1. Per Diem Base Calculation
- **Base per diem rate**: $100 per day
- **Formula**: `base_per_diem = trip_duration_days × $100`

### 2. Trip Duration Bonuses
- **5-day trip bonus**: +$75 (consistently applied)
- **8-day trip bonus**: +$40 (in addition to base)
- **14-day trip bonus**: +$50 (in addition to base)
- **Exception**: Some 5-day trips don't get the bonus (unknown trigger condition)

### 3. Mileage Calculation (Tiered System)
The system uses a complex tiered mileage reimbursement structure:

#### Tier 1: 0-100 miles
- Rate: $0.58 per mile
- Formula: `miles × $0.58`

#### Tier 2: 101-500 miles  
- Rate: $0.40 per mile for miles above 100
- Formula: `$58 + (miles - 100) × $0.40`

#### Tier 3: 501+ miles
- Rate: $0.25 per mile for miles above 500
- Additional bonus for 800+ miles: +$0.05 per mile above 800
- Formula: `$58 + $160 + (miles - 500) × $0.25 + bonus_if_over_800`

**Note**: The mileage calculation is described as "some kind of curve" - not linear, possibly logarithmic in nature.

### 4. Receipt Processing Rules

#### Basic Receipt Adjustment
- **Very low receipts** (< $50): Penalty applied, often worse than no receipts
- **Optimal range** ($600-$800): Receives bonus treatment (+$40)
- **High receipts** (> $800): Diminishing returns applied

#### Receipt Multipliers by Trip Length
- **1-2 day trips**: 0.8× multiplier for receipts ≤ $800, 0.1× for excess
- **3-5 day trips**: 0.7× multiplier for receipts ≤ $800, 0.05× for excess  
- **6+ day trips**: 0.5× multiplier for receipts ≤ $800, 0.02× for excess

#### High Receipt Penalties
- When `receipts > $1000`: Per diem and mileage reduced to 80% of calculated value
- Multi-day trips with `receipts < $50`: 10% reduction in per diem + $100 penalty

### 5. Efficiency Bonus System
- **Trigger**: Miles per day > 150
- **Formula**: `(miles_per_day - 150) × $0.5`
- **Cap**: Maximum efficiency bonus of $75
- **Sweet spot**: 180-220 miles per day for maximum bonuses
- **Diminishing returns**: Beyond 400 miles/day, system assumes less actual business activity

### 6. Known System Bugs/Quirks

#### Rounding Bug
- **Trigger**: Receipt amounts ending in .49, .99, or .50 cents
- **Effect**: +$5 bonus (appears to be a rounding error that became institutionalized)

#### Special Case Handling for 1-Day Trips
- If total calculated amount > $500: Apply 50% reduction to excess over $500
- Formula: `$500 + (total - $500) × 0.5`

### 7. Special Penalties and Bonuses

#### High Receipt Penalties (4, 8, 14-day trips)
- Base penalty: +$200 + `(receipts - $1000) × 0.05`
- Additional 14-day penalty for receipts > $2000: `+(receipts - $2000) × 0.15`

#### Low Mileage Penalty (14-day trips)
- If miles < 200: +$300 penalty

#### High Mileage-to-Receipt Ratio Bonus (14-day trips)
- If `miles/receipts > 1.0`: +$60 bonus
- If `miles/receipts > 0.6` but ≤ 1.0: +$125 bonus

## Employee-Reported Behavioral Patterns

### 1. Inconsistency and Variation
- **Observation**: Same trip parameters can yield different results (5-10% variation)
- **Theories**: 
  - Seasonal/quarterly effects (unconfirmed)
  - Submission timing effects (day of week, moon phases)
  - Historical spending pattern influence
  - Intentional randomization to prevent gaming

### 2. Department-Specific Patterns
- **Sales**: Generally better reimbursements (possibly due to experience)
- **Operations**: Mixed results depending on trip optimization
- **Finance/Accounting**: Conservative spending, generally satisfied with results

### 3. Optimization Strategies (Per Kevin from Procurement)
- **Sweet Spot Combo**: 5-day trips + 180+ miles/day + <$100/day spending = guaranteed bonus
- **Vacation Penalty**: 8+ day trips + high spending = guaranteed penalty
- **Submission Timing**: Tuesday submissions outperform Friday by ~8%
- **Lunar Correlation**: New moon submissions ~4% higher than full moon

### 4. User Experience Patterns
- **New employees**: Lower initial reimbursements (learning curve)
- **Experienced users**: Better results through system knowledge
- **Small receipts**: Better to submit nothing than small amounts
- **Strategic planning**: Some users plan routes/timing to optimize reimbursements

## System Architecture Theories

### Calculation Paths
The system appears to have at least 6 different calculation paths based on trip characteristics:
1. Quick high-mileage trips
2. Long low-mileage trips  
3. Medium balanced trips
4. Single-day trips
5. Extended trips (8+ days)
6. Ultra-long trips (14+ days)

### Hidden Factors
Suspected but unconfirmed factors that may influence calculations:
- Historical user spending patterns
- Market conditions or company performance
- Randomization algorithms tied to external data
- User profile/department classification
- Submission date/timing effects

## Implementation Notes

### Bugs to Preserve
1. **Rounding bug**: Receipt amounts ending in .49, .99, .50 get +$5 bonus
2. **Small receipt penalty**: Better to submit $0 than small amounts
3. **Non-linear interactions**: Complex interaction effects between trip length, mileage, and spending

### Edge Cases
1. **Single-day high-cost trips**: Special capping logic
2. **14-day trips**: Multiple additional rules and bonuses/penalties
3. **Zero or very low receipts**: Penalty system for multi-day trips

### Key Insight
The system appears to have evolved over 60 years with multiple layers of rules, exceptions, bonuses, and penalties added over time. The complexity suggests it was designed to:
- Encourage efficient business travel
- Discourage gaming or excessive spending
- Provide variable outcomes to prevent optimization
- Accommodate different types of business trips

The challenge is not just implementing the mathematical formulas, but replicating the complex interaction effects and edge cases that have accumulated over decades of system evolution.
