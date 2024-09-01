import pandas as pd
import numpy as np
from scipy.interpolate import interp1d

def resample_data(case_num):
    interpolated_df = pd.read_csv(f'.temp/case{case_num}/GroundTruth.csv')
    arcore_df = pd.read_csv(f'input/case{case_num}/ARCoreData.csv')

    arcore_df['X'] = arcore_df['DirectionX']
    arcore_df['Y'] = arcore_df['DirectionZ']
    arcore_df['Z'] = arcore_df['DirectionY']

    # Timestamp for resampling
    start_time = max(interpolated_df['Timestamp'].min(), arcore_df['Timestamp'].min())
    end_time = min(interpolated_df['Timestamp'].max(), arcore_df['Timestamp'].max())
    interpolated_df = interpolated_df[(interpolated_df['Timestamp'] >= start_time) & (interpolated_df['Timestamp'] <= end_time)]
    arcore_df = arcore_df[(arcore_df['Timestamp'] >= start_time) & (arcore_df['Timestamp'] <= end_time)]

    resample_rate = 1/60
    resample_times = np.arange(start_time, end_time, resample_rate)

    def resample_data(df, resample_times):
        interp_func = interp1d(df['Timestamp'], df.iloc[:, 1:], kind='linear', axis=0, fill_value="extrapolate")
        resampled_data = interp_func(resample_times)
        return pd.DataFrame(resampled_data, columns=df.columns[1:], index=resample_times)

    interpolated_resampled = resample_data(interpolated_df, resample_times)
    arcore_resampled = resample_data(arcore_df, resample_times)

    def move_origin(df1, df2):
        origin_df1 = df1.loc[df1.index[0], ['X', 'Y', 'Z']]
        origin_df2 = df2.loc[df2.index[0], ['X', 'Y', 'Z']]
        
        offset = origin_df2 - origin_df1
        
        adjusted_df1 = df1.copy()
        adjusted_df2 = df2.copy()
        
        for coord in ['X', 'Y', 'Z']:
            adjusted_df2[coord] = df2[coord] - offset[coord]
        
        return adjusted_df1, adjusted_df2

    interpolated_resampled_aligned_origin, arcore_resampled_aligned_origin = move_origin(interpolated_resampled, arcore_resampled)

    interpolated_resampled_aligned_origin.to_csv(f'.temp/case{case_num}/resampled_truth.csv', index=False)
    arcore_resampled_aligned_origin.to_csv(f'.temp/case{case_num}/resampled_arcore.csv', index=False)

start_number = int(input('Input start index of the case number: '))
end_number = int(input('Input end index of the case number: '))

for i in range(start_number, end_number + 1):
    print(f'Processing case {i}')
    resample_data(i)
