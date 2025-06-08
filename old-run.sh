#!/bin/bash
# Prototype reimbursement logic for ACME legacy system
# Usage: ./run.sh <trip_duration_days> <miles_traveled> <total_receipts_amount>

trip_days=$1
miles=$2
receipts=$3

# --- Per Diem ---
per_diem=100
base_per_diem=$(echo "$trip_days * $per_diem" | bc)

# 5-day bonus
bonus=0
if [ "$trip_days" -eq 5 ]; then
  bonus=75
fi

# 8-day bonus (less pronounced)
if [ "$trip_days" -eq 8 ]; then
  bonus=$(echo "$bonus + 40" | bc)
fi

# --- Mileage ---
# Tiered rates: first 100 @ 0.58, next 400 @ 0.40, above 500 @ 0.25
mileage=0
if (( $(echo "$miles <= 100" | bc -l) )); then
  mileage=$(echo "$miles * 0.58" | bc)
elif (( $(echo "$miles <= 500" | bc -l) )); then
  mileage=$(echo "100 * 0.58 + ($miles - 100) * 0.40" | bc)
else
  mileage=$(echo "100 * 0.58 + 400 * 0.40 + ($miles - 500) * 0.25" | bc)
fi

# --- Receipts ---
# Dynamic: receipts reimbursement depends on trip length and amount
receipts_adj=0
if (( $(echo "$receipts < 50" | bc -l) )); then
  receipts_adj=0
elif (( $(echo "$receipts <= 800" | bc -l) )); then
  # For short trips, reimburse more; for long trips, less
  if [ "$trip_days" -le 2 ]; then
    receipts_adj=$(echo "$receipts * 0.8" | bc)
  elif [ "$trip_days" -le 5 ]; then
    receipts_adj=$(echo "$receipts * 0.7" | bc)
  else
    receipts_adj=$(echo "$receipts * 0.5" | bc)
  fi
else
  # Diminishing returns above $800
  if [ "$trip_days" -le 2 ]; then
    receipts_adj=$(echo "800 * 0.8 + ($receipts - 800) * 0.1" | bc)
  elif [ "$trip_days" -le 5 ]; then
    receipts_adj=$(echo "800 * 0.7 + ($receipts - 800) * 0.05" | bc)
  else
    receipts_adj=$(echo "800 * 0.5 + ($receipts - 800) * 0.02" | bc)
  fi
fi

# --- Per Diem & Mileage Soft Reductions ---
per_diem_adj=$base_per_diem
mileage_adj=$mileage
if (( $(echo "$receipts > 1000" | bc -l) )); then
  per_diem_adj=$(echo "$base_per_diem * 0.8" | bc)
  mileage_adj=$(echo "$mileage * 0.8" | bc)
fi

# --- Penalty for multi-day trips with low receipts ---
penalty=0
if [ "$trip_days" -gt 1 ] && (( $(echo "$receipts < 50" | bc -l) )); then
  per_diem_adj=$(echo "$per_diem_adj * 0.9" | bc)
fi

# --- Efficiency Bonus ---
efficiency=0
mpd=$(echo "$miles / $trip_days" | bc -l)
if (( $(echo "$mpd > 150" | bc -l) )); then
  efficiency=$(echo "($mpd - 150) * 0.5" | bc)
fi

# --- Rounding Bug ---
rounding_bonus=0
cents=$(echo "$receipts - (scale=0; $receipts/1)*1" | bc)
if [[ "$cents" == ".49" || "$cents" == ".99" ]]; then
  rounding_bonus=5
fi

# --- Special Case Penalties/Bonuses ---
# For 1-day trips, introduce a soft cap with diminishing returns above $500
if [ "$trip_days" -eq 1 ]; then
  total=$(echo "$base_per_diem + $bonus + $mileage + $receipts_adj + $efficiency + $rounding_bonus" | bc)
  if (( $(echo "$total > 500" | bc -l) )); then
    excess=$(echo "$total - 500" | bc)
    total=$(echo "500 + $excess * 0.5" | bc)  # Apply 50% diminishing returns above $500
  fi
  printf "%.2f\n" "$total"
  exit 0
fi

# Scale penalty for high receipts based on amount and trip duration
if { [ "$trip_days" -eq 4 ] || [ "$trip_days" -eq 8 ] || [ "$trip_days" -eq 14 ]; } && (( $(echo "$receipts > 1000" | bc -l) )); then
  penalty=$(echo "200 + ($receipts - 1000) * 0.05" | bc)  # Add 5% of excess receipts above $1000
else
  penalty=0
fi

# Contextualize penalty for low receipts based on mileage and efficiency
if [ "$trip_days" -gt 1 ] && (( $(echo "$receipts < 50" | bc -l) )); then
  low_receipts_penalty=$(echo "50 - $mileage * 0.02 - $efficiency * 0.1" | bc)  # Reduce penalty based on mileage and efficiency
  penalty=$(echo "$penalty + $low_receipts_penalty" | bc)
fi

# Cap efficiency bonus to prevent overcompensation
if (( $(echo "$efficiency > 100" | bc -l) )); then
  efficiency=$(echo "100 + ($efficiency - 100) * 0.5" | bc)  # Apply 50% diminishing returns above 100
fi

# Expand rounding bonus logic
cents=$(echo "$receipts - (scale=0; $receipts/1)*1" | bc)
if [[ "$cents" == ".49" || "$cents" == ".99" || "$cents" == ".50" ]]; then  # Include .50 as a bonus case
  rounding_bonus=5
fi

# --- Adjust 8-day trip logic ---
if [ "$trip_days" -eq 8 ]; then
  # Add mileage-based bonus for high mileage
  if (( $(echo "$miles > 800" | bc -l) )); then
    bonus=$(echo "$bonus + 100" | bc)  # Add $100 bonus for mileage above 800
  fi

  # Scale penalty for high receipts above $1200
  if (( $(echo "$receipts > 1200" | bc -l) )); then
    penalty=$(echo "$penalty + ($receipts - 1200) * 0.1" | bc)  # Add 10% penalty for excess receipts
  fi

  # Reward high mileage-to-receipts ratio
  mileage_to_receipts=$(echo "$miles / $receipts" | bc -l)
  if (( $(echo "$mileage_to_receipts > 0.5" | bc -l) )); then
    bonus=$(echo "$bonus + 50" | bc)  # Add $50 bonus for high mileage-to-receipts ratio
  fi
fi

# --- Adjust 7-day trip logic ---
if [ "$trip_days" -eq 7 ]; then
  # Add mileage-based bonus for high mileage
  if (( $(echo "$miles > 1000" | bc -l) )); then
    bonus=$(echo "$bonus + 150" | bc)  # Add $150 bonus for mileage above 1000
  fi

  # Scale receipts adjustment for $1000-$1200 range
  if (( $(echo "$receipts >= 1000 && $receipts <= 1200" | bc -l) )); then
    receipts_adj=$(echo "$receipts_adj + ($receipts - 1000) * 0.2" | bc)  # Add 20% of receipts in this range
  fi

  # Reward high mileage-to-receipts ratio
  mileage_to_receipts=$(echo "$miles / $receipts" | bc -l)
  if (( $(echo "$mileage_to_receipts > 0.8" | bc -l) )); then
    bonus=$(echo "$bonus + 75" | bc)  # Add $75 bonus for high mileage-to-receipts ratio
  fi
fi

# --- Refine 14-day trip logic ---
if [ "$trip_days" -eq 14 ]; then
  # Add bonus for high mileage (smooth curve: +$150 for >500, +$200 for >800)
  if (( $(echo "$miles > 800" | bc -l) )); then
    bonus=$(echo "$bonus + 200" | bc)  # Add $200 bonus for mileage above 800
  elif (( $(echo "$miles > 500" | bc -l) )); then
    bonus=$(echo "$bonus + 150" | bc)  # Add $150 bonus for mileage above 500
  fi

  # Penalize very low mileage
  if (( $(echo "$miles < 200" | bc -l) )); then
    penalty=$(echo "$penalty + 300" | bc)  # Increase penalty for mileage below 200
  fi

  # Scale receipts adjustment for $500-$1000 range
  if (( $(echo "$receipts >= 500 && $receipts <= 1000" | bc -l) )); then
    receipts_adj=$(echo "$receipts_adj + ($receipts - 500) * 0.5" | bc)  # Increase to 50% of receipts in this range
  fi

  # Bonus for receipts in $600-$800 range (modest spending)
  if (( $(echo "$receipts >= 600 && $receipts <= 800" | bc -l) )); then
    bonus=$(echo "$bonus + 40" | bc)  # Add $40 bonus for modest receipts
  fi

  # Increase penalty for very high receipts
  if (( $(echo "$receipts > 2000" | bc -l) )); then
    penalty=$(echo "$penalty + ($receipts - 2000) * 0.15" | bc)  # 15% penalty for receipts above $2000
  fi

  # Reward high mileage-to-receipts ratio
  mileage_to_receipts=$(echo "$miles / $receipts" | bc -l)
  if (( $(echo "$mileage_to_receipts > 1.0" | bc -l) )); then
    bonus=$(echo "$bonus + 60" | bc)  # Add $60 bonus for very high mileage-to-receipts ratio
  elif (( $(echo "$mileage_to_receipts > 0.6" | bc -l) )); then
    bonus=$(echo "$bonus + 125" | bc)  # Add $125 bonus for high mileage-to-receipts ratio
  fi

  # Legacy quirk: Add fixed bonus for 14-day trips
  bonus=$(echo "$bonus + 50" | bc)  # Add $50 fixed bonus for all 14-day trips

  # Cap efficiency bonus for 14-day trips
  if (( $(echo "$efficiency > 75" | bc -l) )); then
    efficiency=75
  fi

  # Make penalty for low receipts more severe for 14-day trips
  if (( $(echo "$receipts < 50" | bc -l) )); then
    penalty=$(echo "$penalty + 100" | bc)  # Add $100 penalty for very low receipts
  fi
fi

# --- Total ---
total=$(echo "$per_diem_adj + $bonus + $mileage_adj + $receipts_adj + $efficiency + $rounding_bonus - $penalty" | bc)
# Round to 2 decimals
printf "%.2f\n" "$total"
