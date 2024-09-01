import pandas as pd
import numpy as np
import os

# Initial coordinates [mm]
x_anchor = 0
y_anchor = 0
z_anchor = 1000

# Acceleration during leaving [mm/s^2]
acceleration_leave = -80

# Deceleration during leaving [mm/s^2]
deceleration_leave = 80

# Acceleration during coming back [mm/s^2]
acceleration_come = 80

# Deceleration during coming back [mm/s^2]
deceleration_come = -80

# Constant velocity during leaving [mm/s]
velocity_leave = -80

# Constant velocity during coming back [mm/s]
velocity_come = 80

# Sampling interval
time_sample = 1 / 60

def load_csv(file_name):
    csv_data = pd.read_csv(file_name)
    csv_data['X Coordinate'] = csv_data['X Coordinate'] / 100 * (-1)
    return csv_data

def calculate_coordinates(interpolated_data, start_time, end_time, start_x, end_x, velocity, acceleration, deceleration):
    # Think of a trapezoid on the v-t graph

    # Bottom base (travel time)
    time_all = end_time - start_time

    # Height: velocity (fixed here)

    # Area (displacement)
    x_total = end_x - start_x

    # Top base (constant velocity time)
    time_constant = x_total * 2 / velocity - time_all
    
    # Projections of the other 2 sides (acceleration or deceleration time)
    time_acc = 0.5 * (time_all - time_constant)
    time_dec = 0.5 * (time_all - time_constant)

    # Acceleration phase
    t = 0
    while t < time_acc:
        x = start_x + 0.5 * acceleration * t**2
        interpolated_data.append([start_time + t, x, y_anchor, z_anchor])
        t += time_sample
    x_start_constant = x # Use the last data as the next initial position

    # Constant velocity phase
    t = 0
    while t < time_constant:
        x = x_start_constant + velocity * t
        interpolated_data.append([start_time + time_acc + t, x, y_anchor, z_anchor])
        t += time_sample
    x_start_dec = x # Use the last data as the next initial position

    # Deceleration phase
    t = 0
    while t < time_dec:
        x = x_start_dec + velocity * t + 0.5 * deceleration * t**2
        interpolated_data.append([start_time + time_acc + time_constant + t, x, y_anchor, z_anchor])
        t += time_sample
    
    return interpolated_data

def insert_zero_coordinates(interpolated_data, start_time, end_time, start_x, end_x):
    # Sampling interval
    time_sample = (end_time - start_time) / 60  # 60Hz

    t_insert_start = interpolated_data[-1][0]
    t_insert = start_time - t_insert_start
    x_insert_start = interpolated_data[-1][1]

    t = 0
    while t < t_insert:
        t += time_sample
        interpolated_data.append([t_insert_start + t, x_insert_start, y_anchor, z_anchor])

    return interpolated_data

## convert mm to m and add offset from the center of QR
def convert_to_required_format(interpolated_df, offset):
    required_df = pd.DataFrame()
    required_df['Timestamp'] = interpolated_df['Timestamp']
    required_df['Distance'] = ((interpolated_df['X Coordinate']**2 + interpolated_df['Y Coordinate']**2 + interpolated_df['Z Coordinate']**2)**0.5) / 1000
    required_df['X'] = interpolated_df['X Coordinate'] / 1000 + offset
    required_df['Y'] = y_anchor / 1000
    required_df['Z'] = z_anchor / 1000
    return required_df

def interpolate_data(df):
    interpolated_data = []

    for i in range(0, len(df) - 1, 2):
        command_start = df.iloc[i]['Event']
        command_end = df.iloc[i + 1]['Event']
        start_time = df.iloc[i]['Time']
        end_time = df.iloc[i + 1]['Time']
        start_x = df.iloc[i]['X Coordinate']
        end_x = df.iloc[i + 1]['X Coordinate']

        if command_start == 'Start leaving' and command_end == 'Finish leaving':
            if len(interpolated_data) != 0:
                insert_zero_coordinates(interpolated_data, start_time, end_time, start_x, end_x)
            interpolated_data = calculate_coordinates(interpolated_data, start_time, end_time, start_x, end_x, velocity_leave, acceleration_leave, deceleration_leave)
        elif command_start == 'Start coming back' and command_end == 'Finish coming back':
            insert_zero_coordinates(interpolated_data, start_time, end_time, start_x, end_x)
            interpolated_data = calculate_coordinates(interpolated_data, start_time, end_time, start_x, end_x, velocity_come, acceleration_come, deceleration_come)
        else:
            print('error')
            exit(0)

    return pd.DataFrame(interpolated_data, columns=['Timestamp', 'X Coordinate', 'Y Coordinate', 'Z Coordinate'])

def write_to_csv(df, file_name):
    df.to_csv(file_name, index=False)

start_number = int(input('Input start index of the case number: '))
end_number = int(input('Input end index of the case number: '))
offset = float(input('Input the offset [m] between QR and initial phone position: '))

for i in range(start_number, end_number + 1):
    print(f'Processing case {i}')

    if not os.path.exists('.temp'):
        os.makedirs('.temp')
    dir_case = f'.temp/case{i}'
    if not os.path.exists(dir_case):
        os.makedirs(dir_case)
    
    file_name = f'input/case{i}/output.csv'
    output_file_name = f'.temp/case{i}/GroundTruth.csv'

    df = load_csv(file_name)
    interpolated_df = interpolate_data(df)
    required_df = convert_to_required_format(interpolated_df, offset)
    write_to_csv(required_df, output_file_name)
