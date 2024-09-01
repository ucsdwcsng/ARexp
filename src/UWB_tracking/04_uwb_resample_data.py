import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d

def resample_data(case_num):
    interpolated_df = pd.read_csv(f'.temp/case{case_num}/GroundTruth.csv')
    uwb_df = pd.read_csv(f'.temp/case{case_num}/data_uwb.csv')
    uwb_raw_df = pd.read_csv(f'.temp/case{case_num}/output_uwb.csv')
    acc_df = pd.read_csv(f'.temp/case{case_num}/data_acc.csv')
    gyro_df = pd.read_csv(f'.temp/case{case_num}/data_gyro.csv')
    mag_df = pd.read_csv(f'.temp/case{case_num}/data_mag.csv')

    uwb_raw_df = uwb_raw_df.drop('Data_type', axis=1)
    
    start_time = max(interpolated_df['Timestamp'].min(), uwb_df['Timestamp'].min(), acc_df['Timestamp'].min(), gyro_df['Timestamp'].min(), mag_df['Timestamp'].min())
    end_time = min(interpolated_df['Timestamp'].max(), uwb_df['Timestamp'].max(), acc_df['Timestamp'].max(), gyro_df['Timestamp'].max(), mag_df['Timestamp'].max())
    interpolated_df = interpolated_df[(interpolated_df['Timestamp'] >= start_time) & (interpolated_df['Timestamp'] <= end_time)]
    uwb_df = uwb_df[(uwb_df['Timestamp'] >= start_time) & (uwb_df['Timestamp'] <= end_time)]
    uwb_raw_df = uwb_raw_df[(uwb_raw_df['Timestamp'] >= start_time) & (uwb_raw_df['Timestamp'] <= end_time)]
    acc_df = acc_df[(acc_df['Timestamp'] >= start_time) & (acc_df['Timestamp'] <= end_time)]
    gyro_df = gyro_df[(gyro_df['Timestamp'] >= start_time) & (gyro_df['Timestamp'] <= end_time)]
    mag_df = mag_df[(mag_df['Timestamp'] >= start_time) & (mag_df['Timestamp'] <= end_time)]

    resample_rate = 1/60  # 60Hz
    resample_times = np.arange(start_time, end_time, resample_rate)

    def resample_data(df, resample_times):
        interp_func = interp1d(df['Timestamp'], df.iloc[:, 1:], kind='linear', axis=0, fill_value="extrapolate")
        resampled_data = interp_func(resample_times)
        return pd.DataFrame(resampled_data, columns=df.columns[1:], index=resample_times)
    
    interpolated_resampled = resample_data(interpolated_df, resample_times)
    uwb_resampled = resample_data(uwb_df, resample_times)
    uwb_raw_resampled = resample_data(uwb_raw_df, resample_times)
    acc_resampled = resample_data(acc_df, resample_times)
    gyro_resampled = resample_data(gyro_df, resample_times)
    mag_resampled = resample_data(mag_df, resample_times)

    def move_origin(df1, df2):
        origin_df1 = df1.loc[df1.index[0], ['X', 'Y', 'Z']]
        origin_df2 = df2.loc[df2.index[0], ['X', 'Y', 'Z']]
        
        offset = origin_df2 - origin_df1
        
        adjusted_df1 = df1.copy()
        adjusted_df2 = df2.copy()
        
        for coord in ['X', 'Y', 'Z']:
            adjusted_df2[coord] = df2[coord] - offset[coord]
        
        return adjusted_df1, adjusted_df2

    interpolated_resampled_aligned_origin, uwb_resampled_aligned_origin = move_origin(interpolated_resampled, uwb_resampled)

    interpolated_resampled_aligned_origin.to_csv(f'.temp/case{case_num}/resampled_truth.csv', index=False)
    uwb_resampled_aligned_origin.to_csv(f'.temp/case{case_num}/resampled_uwb.csv', index=False)
    uwb_raw_resampled.to_csv(f'.temp/case{case_num}/resampled_uwb_raw.csv', index=False)
    acc_resampled.to_csv(f'.temp/case{case_num}/resampled_acc.csv', index=False)
    gyro_resampled.to_csv(f'.temp/case{case_num}/resampled_gyro.csv', index=False)
    mag_resampled.to_csv(f'.temp/case{case_num}/resampled_mag.csv', index=False)

start_number = int(input('Input start index of the case number: '))
end_number = int(input('Input end index of the case number: '))

for i in range(start_number, end_number + 1):
    print(f'Processing case {i}')
    resample_data(i)
