import pandas as pd
import numpy as np
import os

def calc_distance(x, y):
    return np.sqrt(x**2 + y**2)

case_number = int(input('Input the case number: '))
x = float(input('Input x [m] of UWB tag: '))
y = float(input('Input y [m] of UWB tag: '))
distances = []
truth_distance = calc_distance(x, y)

for i in range(5):
    try:
        df = pd.read_csv(f'input/case{case_number}/localization_{i}.csv')
        condition = df[df['Distance'] == 'uwb']
        condition = condition[(condition['Azimuth'] != 0) & (condition['Elevation'] != 0) & (condition['AccX'] != 0)]
        if not condition.empty:
            distances.append(abs(condition['Azimuth'].iloc[0] - truth_distance))
    except FileNotFoundError:
        print(f"File input/case{case_number}/localization_{i}.csv not found.")

output_dir = f'output/case{case_number}'
os.makedirs(output_dir, exist_ok=True)

if distances:
    average_distance = np.mean(distances)
    results_df = pd.DataFrame([[case_number, average_distance]], columns=['Case', 'Average error [m]'])
    results_df.to_csv(f'{output_dir}/error.csv', index=False)
    print(f'Average Error for Case {case_number}: {average_distance}')
    print(f'Results saved to {output_dir}/error.csv')
else:
    print(f'No valid data found for Case {case_number}.')
