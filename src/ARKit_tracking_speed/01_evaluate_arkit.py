import csv
import math
import matplotlib.pyplot as plt
import numpy as np
import os
import pandas as pd
from scipy.interpolate import interp1d
from sklearn.linear_model import LinearRegression
import seaborn as sns

def trim_data(csv_vive, csv_arkit, csv_vive_trimmed, csv_arkit_trimmed, time_ready):
    df_vive = pd.read_csv(csv_vive)
    df_arkit = pd.read_csv(csv_arkit)

    # Determine timestamp range for each dataset
    start_time = max(df_vive['Timestamp'].min(), df_arkit['Timestamp'].min())
    end_time = min(df_vive['Timestamp'].max(), df_arkit['Timestamp'].max())

    # Assume that the experiment starts time_ready seconds after both devices start recording
    start_time = start_time + time_ready

    # Trim data based on common timestamp ranges
    df_vive_trimmed = df_vive[(df_vive['Timestamp'] >= start_time) & (df_vive['Timestamp'] <= end_time)]
    df_arkit_trimmed = df_arkit[(df_arkit['Timestamp'] >= start_time) & (df_arkit['Timestamp'] <= end_time)]

    # Output trimmed data (.csv)
    df_vive_trimmed.to_csv(csv_vive_trimmed, index=False)
    df_arkit_trimmed.to_csv(csv_arkit_trimmed, index=False)

def resample_data(csv_vive_trimmed, csv_arkit_trimmed, csv_vive_resampled, csv_vive_velocity_resampled, csv_arkit_resampled):
    df_vive = pd.read_csv(csv_vive_trimmed)
    df_arkit = pd.read_csv(csv_arkit_trimmed)

    start_vive = df_vive['Timestamp'].iloc[0]
    end_vive = df_vive['Timestamp'].iloc[-1]
    start_arkit = df_arkit['Timestamp'].iloc[0]
    end_arkit = df_arkit['Timestamp'].iloc[-1]

    interpolator_vive = interp1d(df_vive['Timestamp'], df_vive[['X', 'Y', 'Z']], axis=0)
    interpolator_vive_velocity = interp1d(df_vive['Timestamp'], df_vive[['Vx', 'Vy', 'Vz']], axis=0)
    interpolator_arkit = interp1d(df_arkit['Timestamp'], df_arkit[['DirectionX', 'DirectionY', 'DirectionZ']], axis=0)

    resampled_time_vive = np.arange(math.ceil(start_vive), math.floor(end_vive), 0.016667) # 60Hz resampling
    resampled_time_arkit = np.arange(math.ceil(start_arkit), math.floor(end_arkit), 0.016667)

    if not np.isclose(resampled_time_vive[-1], end_vive):
        resampled_time_vive = np.append(resampled_time_vive, end_vive)
    if not np.isclose(resampled_time_arkit[-1], end_arkit):
        resampled_time_arkit = np.append(resampled_time_arkit, end_arkit)

    resampled_values_vive = interpolator_vive(resampled_time_vive)
    resampled_values_vive_velocity = interpolator_vive_velocity(resampled_time_vive)
    resampled_values_arkit = interpolator_arkit(resampled_time_arkit)
    
    df_resampled_vive = pd.DataFrame(resampled_values_vive, columns=['X', 'Y', 'Z'])
    df_resampled_vive['Timestamp'] = resampled_time_vive
    df_resampled_vive_velocity = pd.DataFrame(resampled_values_vive_velocity, columns=['Vx', 'Vy', 'Vz'])
    df_resampled_vive_velocity['Timestamp'] = resampled_time_vive
    df_resampled_arkit = pd.DataFrame(resampled_values_arkit, columns=['DirectionX', 'DirectionY', 'DirectionZ'])
    df_resampled_arkit['Timestamp'] = resampled_time_arkit

    df_resampled_vive.to_csv(csv_vive_resampled, index=False)
    df_resampled_vive_velocity.to_csv(csv_vive_velocity_resampled, index=False)
    df_resampled_arkit.to_csv(csv_arkit_resampled, index=False)
    
def calibrate_data(csv_vive_resampled, csv_arkit_resampled, csv_vive_calibrated, csv_arkit_calibrated, anchor_coordinate):
    df_vive = pd.read_csv(csv_vive_resampled)
    df_arkit = pd.read_csv(csv_arkit_resampled)
    
    first_vive = df_vive.iloc[0][['X', 'Y', 'Z']]
    first_arkit = df_arkit.iloc[0][['DirectionX', 'DirectionY', 'DirectionZ']]

    offset = first_vive.values - first_arkit.values
    
    anchor_coordinate_np = first_arkit.values
    anchor_coordinate_np[2] -= 1
    anchor_coordinate_np += offset

    df_arkit_calibrated = df_arkit.copy()
    df_arkit_calibrated[['DirectionX', 'DirectionY', 'DirectionZ']] += offset

    df_vive.to_csv(csv_vive_calibrated, index=False)
    df_arkit_calibrated.to_csv(csv_arkit_calibrated, index=False)

    return anchor_coordinate_np.tolist()

def extract_trajectory(csv_vive_calibrated, csv_arkit_calibrated, anchor_coordinate):
    df_vive = pd.read_csv(csv_vive_calibrated)
    df_arkit = pd.read_csv(csv_arkit_calibrated)
    
    fig, ax = plt.subplots(figsize=(8, 6))

    ax.scatter(df_vive['X'], df_vive['Z'], label='VIVE', marker='o', s=1, zorder=0)
    ax.scatter(df_arkit['DirectionX'], df_arkit['DirectionZ'], label='ARKit', marker='x', s=1, zorder=1)
    ax.scatter(anchor_coordinate[0], anchor_coordinate[2], label='Anchor', marker='*', s=200, zorder=2)
    ax.set_xlabel('X [m]')
    ax.set_ylabel('Y [m]')
    ax.legend()

    return plt

def extract_velocity_error(csv_vive_calibrated, csv_arkit_calibrated, csv_vive_velocity_resampled, csv_velocity_error):
    df_vive = pd.read_csv(csv_vive_calibrated)
    df_vive_velocity = pd.read_csv(csv_vive_velocity_resampled)
    df_arkit = pd.read_csv(csv_arkit_calibrated)

    results = []

    for timestamp in df_vive['Timestamp'].unique():
        vive_row = df_vive[df_vive['Timestamp'] == timestamp]
        arkit_row = df_arkit[df_arkit['Timestamp'] == timestamp]
        vive_velocity_row = df_vive_velocity[df_vive_velocity['Timestamp'] == timestamp]
        vive_velocity_norm = np.linalg.norm(vive_velocity_row[['Vx', 'Vy', 'Vz']].values)

        if not arkit_row.empty and not vive_row.empty:
            euclidean_distance = np.linalg.norm(vive_row[['X', 'Y', 'Z']].values - arkit_row[['DirectionX', 'DirectionY', 'DirectionZ']].values)
        else:
            euclidean_distance = np.nan

        results.append([timestamp, vive_velocity_norm, euclidean_distance])

    result_df = pd.DataFrame(results, columns=['Timestamp', 'VIVE_Velocity_Norm', 'Euclidean_Distance'])
    result_df.to_csv(csv_velocity_error, index=False)

def plot_velocity_error_barchart(csv_velocity_error):
    df = pd.read_csv(csv_velocity_error)
    df['Velocity_Bin'] = pd.cut(df['VIVE_Velocity_Norm'], bins=10)
    plt.figure(figsize=(8, 6))
    sns.boxplot(x='Velocity_Bin', y='Euclidean_Distance', data=df)
    plt.xlabel('Velocity bin [m/s]')
    plt.ylabel('Error [m]')
    plt.xticks(rotation=45)
    return plt
    
def main():
    case_number = input('Please enter the case number (ex. 0 for case0): ')
    time_ready = float(input('Please input the ready time after start both devices with float [s]: '))
    log_vive = f'input/case{case_number}/VIVE.log'
    csv_arkit = f'input/case{case_number}/ARKitData.csv'
    csv_vive = f'.temp/case{case_number}/VIVE.csv'
    csv_vive_trimmed = f'.temp/case{case_number}/VIVE_trimmed.csv'
    csv_arkit_trimmed = f'.temp/case{case_number}/ARKitData_trimmed.csv'
    csv_vive_resampled = f'.temp/case{case_number}/VIVE_resampled.csv'
    csv_vive_velocity_resampled = f'.temp/case{case_number}/VIVE_velocity_resampled.csv'
    csv_arkit_resampled = f'.temp/case{case_number}/ARKitData_resampled.csv'
    csv_vive_calibrated = f'.temp/case{case_number}/VIVE_calibrated.csv'
    csv_arkit_calibrated = f'.temp/case{case_number}/ARKitData_calibrated.csv'
    csv_velocity_error = f'output/case{case_number}/velocity_and_error.csv'

    if not os.path.exists('.temp'):
        os.makedirs('.temp')
    if not os.path.exists(f'.temp/case{case_number}'):
        os.makedirs(f'.temp/case{case_number}')
    if not os.path.exists(f'output/case{case_number}'):
        os.makedirs(f'output/case{case_number}')
        
    # anchor
    anchor_coordinate = (0, 0, -1.5)
    trim_data(csv_vive, csv_arkit, csv_vive_trimmed, csv_arkit_trimmed, time_ready)
    resample_data(csv_vive_trimmed, csv_arkit_trimmed, csv_vive_resampled, csv_vive_velocity_resampled, csv_arkit_resampled)
    anchor_coordinate = calibrate_data(csv_vive_resampled, csv_arkit_resampled, csv_vive_calibrated, csv_arkit_calibrated, anchor_coordinate)
    plt = extract_trajectory(csv_vive_calibrated, csv_arkit_calibrated, anchor_coordinate)
    plt.savefig(f'output/case{case_number}/trajectory.png')

    # Save error data of velocity and distance
    extract_velocity_error(csv_vive_calibrated, csv_arkit_calibrated, csv_vive_velocity_resampled, csv_velocity_error)

    plt = plot_velocity_error_barchart(csv_velocity_error)
    plt.savefig(f'output/case{case_number}/velocity_error.png')

if __name__ == "__main__":
    main()
    