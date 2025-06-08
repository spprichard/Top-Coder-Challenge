#!/bin/bash

# Black Box Challenge - Business Rule Approximation
# Usage: ./run.sh <trip_duration_days> <miles_traveled> <total_receipts_amount>

trip_days=$1
miles=$2
receipts=$3

# --- Per Diem ---
per_diem=100
base_per_diem=$(echo "$trip_days * $per_diem" | bc)

# --- Per Diem Bonuses ---
bonus=0
if [ "$trip_days" -eq 5 ]; then
  # TODO: Some 5-day trips do NOT get the bonus (unknown trigger). Placeholder for future logic.
  bonus=75
fi
if [ "$trip_days" -eq 8 ]; then
  bonus=$(echo "$bonus + 40" | bc)
fi
if [ "$trip_days" -eq 14 ]; then
  bonus=$(echo "$bonus + 50" | bc)
fi

# --- Mileage (tiered, with curve) ---
mileage=0
if (( $(echo "$miles <= 100" | bc -l) )); then
  mileage=$(echo "$miles * 0.58" | bc)
elif (( $(echo "$miles <= 500" | bc -l) )); then
  mileage=$(echo "100 * 0.58 + ($miles - 100) * 0.40" | bc)
else
  mileage=$(echo "100 * 0.58 + 400 * 0.40 + ($miles - 500) * 0.25" | bc)
  if (( $(echo "$miles > 800" | bc -l) )); then
    mileage=$(echo "$mileage + ($miles - 800) * 0.05" | bc)
  fi
fi

# --- Receipts (diminishing returns, modest bonus, penalty for low/high) ---
receipts_adj=0
if (( $(echo "$receipts < 50" | bc -l) )); then
  receipts_adj=0
else
  if (( $(echo "$receipts <= 800" | bc -l) )); then
    if [ "$trip_days" -le 2 ]; then
      receipts_adj=$(echo "$receipts * 0.8" | bc)
    elif [ "$trip_days" -le 5 ]; then
      receipts_adj=$(echo "$receipts * 0.7" | bc)
    else
      receipts_adj=$(echo "$receipts * 0.5" | bc)
    fi
    # modest bonus for $600-$800
    if (( $(echo "$receipts >= 600 && $receipts <= 800" | bc -l) )); then
      receipts_adj=$(echo "$receipts_adj + 40" | bc)
    fi
  else
    if [ "$trip_days" -le 2 ]; then
      receipts_adj=$(echo "800 * 0.8 + ($receipts - 800) * 0.1" | bc)
    elif [ "$trip_days" -le 5 ]; then
      receipts_adj=$(echo "800 * 0.7 + ($receipts - 800) * 0.05" | bc)
    else
      receipts_adj=$(echo "800 * 0.5 + ($receipts - 800) * 0.02" | bc)
    fi
  fi
fi

# --- Soft Reductions for high receipts ---
per_diem_adj=$base_per_diem
mileage_adj=$mileage
if (( $(echo "$receipts > 1000" | bc -l) )); then
  per_diem_adj=$(echo "$base_per_diem * 0.8" | bc)
  mileage_adj=$(echo "$mileage * 0.8" | bc)
fi

# --- Penalty for multi-day trips with very low receipts ---
penalty=0
if [ "$trip_days" -gt 1 ] && (( $(echo "$receipts < 50" | bc -l) )); then
  # Severe penalty for multi-day trips with very low receipts
  per_diem_adj=$(echo "$per_diem_adj * 0.9" | bc)
  penalty=$(echo "$penalty + 100" | bc)
fi

# --- Efficiency Bonus (miles per day) ---
efficiency=0
mpd=$(echo "$miles / $trip_days" | bc -l)
if (( $(echo "$mpd > 150" | bc -l) )); then
  efficiency=$(echo "($mpd - 150) * 0.5" | bc)
  if (( $(echo "$efficiency > 75" | bc -l) )); then
    efficiency=75
  fi
  # Diminishing returns for very high MPD (beyond 400 miles/day)
  if (( $(echo "$mpd > 400" | bc -l) )); then
    efficiency=$(echo "$efficiency * 0.8" | bc)
  fi
fi

# --- Rounding Bug ---
rounding_bonus=0
if echo "$receipts" | grep -q '\.[0-9][0-9]$'; then
  cents=$(echo "$receipts" | sed 's/.*\.\([0-9][0-9]\)$/\1/')
  if [[ "$cents" == "49" || "$cents" == "99" || "$cents" == "50" ]]; then
    rounding_bonus=5
  fi
fi

# --- Special Case Penalties/Bonuses ---
if [ "$trip_days" -eq 1 ]; then
  total=$(echo "$base_per_diem + $bonus + $mileage + $receipts_adj + $efficiency + $rounding_bonus" | bc)
  if (( $(echo "$total > 500" | bc -l) )); then
    excess=$(echo "$total - 500" | bc)
    total=$(echo "500 + $excess * 0.5" | bc)
  fi
  printf "%.2f\n" "$total"
  exit 0
fi

# Penalty for high receipts (4, 8, 14 day trips)
if { [ "$trip_days" -eq 4 ] || [ "$trip_days" -eq 8 ] || [ "$trip_days" -eq 14 ]; } && (( $(echo "$receipts > 1000" | bc -l) )); then
  penalty=$(echo "$penalty + 200 + ($receipts - 1000) * 0.05" | bc)
fi
# Extra penalty for very high receipts (14 day)
if [ "$trip_days" -eq 14 ] && (( $(echo "$receipts > 2000" | bc -l) )); then
  penalty=$(echo "$penalty + ($receipts - 2000) * 0.15" | bc)
fi

# Penalty for very low mileage (14 day)
if [ "$trip_days" -eq 14 ] && (( $(echo "$miles < 200" | bc -l) )); then
  penalty=$(echo "$penalty + 300" | bc)
fi

# Bonus for high mileage-to-receipts ratio (14 day)
if [ "$trip_days" -eq 14 ]; then
  if (( $(echo "$receipts == 0" | bc -l) )); then
    mileage_to_receipts=0 # Avoid division by zero
  else
    mileage_to_receipts=$(echo "$miles / $receipts" | bc -l)
  fi
  if (( $(echo "$mileage_to_receipts > 1.0" | bc -l) )); then
    bonus=$(echo "$bonus + 60" | bc)
  elif (( $(echo "$mileage_to_receipts > 0.6" | bc -l) )); then
    bonus=$(echo "$bonus + 125" | bc)
  fi
fi

# --- Total ---
total=$(echo "$per_diem_adj + $bonus + $mileage_adj + $receipts_adj + $efficiency + $rounding_bonus - $penalty" | bc)
printf "%.2f\n" "$total"