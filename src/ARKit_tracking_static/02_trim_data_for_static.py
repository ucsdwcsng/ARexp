import pandas as pd
import os

if not os.path.exists('.temp'):
    os.makedirs('.temp')

def move_origin(df1, df2):
    origin_df1 = df1.loc[df1.index[0], ['X', 'Y', 'Z']]
    origin_df2 = df2.loc[df2.index[0], ['X', 'Y', 'Z']]
    
    offset = origin_df2 - origin_df1
    
    adjusted_df1 = df1.copy()
    adjusted_df2 = df2.copy()
    
    for coord in ['X', 'Y', 'Z']:
        adjusted_df2[coord] = df2[coord] - offset[coord]
    
    return adjusted_df1, adjusted_df2

def trim_data(case_num):
    truth_df = pd.read_csv(f'.temp/case{case_num}/resampled_truth.csv')
    arkit_df = pd.read_csv(f'.temp/case{case_num}/resampled_arkit.csv')

    sampling_rate = 60  # 60Hz
    samples_to_exclude = 5 * sampling_rate  # Last 5s
    samples_for_100s = 100 * sampling_rate  # 100s

    # Trim the last data for 5s and extract 100s data
    truth_df_trimmed = truth_df.iloc[-(samples_to_exclude + samples_for_100s):-samples_to_exclude]
    arkit_df_trimmed = arkit_df.iloc[-(samples_to_exclude + samples_for_100s):-samples_to_exclude]

    adjusted_truth, adjusted_arkit = move_origin(truth_df_trimmed, arkit_df_trimmed)
    adjusted_truth.to_csv(f'.temp/case{case_num}/resampled_truth.csv', index=False)
    adjusted_arkit.to_csv(f'.temp/case{case_num}/resampled_arkit.csv', index=False)

start_number = int(input('Input start index of the case number: '))
end_number = int(input('Input end index of the case number: '))

for i in range(start_number, end_number + 1):
    print(f'Processing case {i}')
    trim_data(i)
