import json
import numpy as np
import matplotlib.pyplot as plt
import os

# Load data
data_path = os.path.join(os.path.dirname(__file__), '..', 'public_cases.json')
with open(data_path, 'r') as f:
    cases = json.load(f)

# Extract fields
trip_days = []
miles = []
receipts = []
outputs = []

for case in cases:
    inp = case['input']
    trip_days.append(inp['trip_duration_days'])
    miles.append(inp['miles_traveled'])
    receipts.append(inp['total_receipts_amount'])
    outputs.append(case['expected_output'])

trip_days = np.array(trip_days)
miles = np.array(miles)
receipts = np.array(receipts)
outputs = np.array(outputs)

# Plot reimbursement vs each input
plt.figure(figsize=(15, 4))
plt.subplot(1, 3, 1)
plt.scatter(trip_days, outputs, alpha=0.5)
plt.xlabel('Trip Duration (days)')
plt.ylabel('Reimbursement')
plt.title('Reimbursement vs Trip Duration')

plt.subplot(1, 3, 2)
plt.scatter(miles, outputs, alpha=0.5)
plt.xlabel('Miles Traveled')
plt.ylabel('Reimbursement')
plt.title('Reimbursement vs Miles')

plt.subplot(1, 3, 3)
plt.scatter(receipts, outputs, alpha=0.5)
plt.xlabel('Total Receipts Amount')
plt.ylabel('Reimbursement')
plt.title('Reimbursement vs Receipts')

plt.tight_layout()
plt.savefig(os.path.join(os.path.dirname(__file__), 'reimbursement_vs_inputs.png'))
plt.close()

# Analyze 5-day and 8-day trips
for special_days in [5, 8]:
    mask = trip_days == special_days
    plt.figure(figsize=(6, 4))
    plt.scatter(miles[mask], outputs[mask], c=receipts[mask], cmap='viridis', alpha=0.7)
    plt.colorbar(label='Receipts')
    plt.xlabel('Miles Traveled')
    plt.ylabel('Reimbursement')
    plt.title(f'Reimbursement for {special_days}-Day Trips')
    plt.tight_layout()
    plt.savefig(os.path.join(os.path.dirname(__file__), f'reimbursement_{special_days}day.png'))
    plt.close()

# Analyze rounding bug: receipts ending in .49 or .99
rounding_mask = np.array([(str(r).endswith('0.49') or str(r).endswith('0.99')) for r in receipts])
plt.figure(figsize=(6, 4))
plt.scatter(receipts[rounding_mask], outputs[rounding_mask], alpha=0.7, color='orange')
plt.xlabel('Receipts ending in .49 or .99')
plt.ylabel('Reimbursement')
plt.title('Rounding Bug Analysis')
plt.tight_layout()
plt.savefig(os.path.join(os.path.dirname(__file__), 'rounding_bug.png'))
plt.close()

print('Analysis complete. Plots saved in scripts/.')
