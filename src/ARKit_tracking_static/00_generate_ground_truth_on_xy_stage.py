import pandas as pd
import numpy as np
import os

start_number = int(input('Input start index of the case number: '))
end_number = int(input('Input end index of the case number: '))

for i in range(start_number, end_number + 1):
    print(f'Processing case {i}')
    
    input_csv_path = f'input/case{i}/ARKitData.csv'
    output_path = f'.temp/case{i}/GroundTruth.csv'
    
    if not os.path.exists(input_csv_path):
        print(f'File not found: {input_csv_path}. Skipping case {i}.')
        continue
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    df = pd.read_csv(input_csv_path)
    df = df[df['Timestamp'] != 0]

    first_timestamp = df['Timestamp'].min()
    last_timestamp = df['Timestamp'].max()

    timestamps = np.arange(first_timestamp, last_timestamp, 1/60)

    ground_truth_df = pd.DataFrame({
        'Timestamp': timestamps,
        'Distance': 1.0,
        'X': 0.0,
        'Y': 0.0,
        'Z': 1.0
    })

    ground_truth_df.to_csv(output_path, index=False)
