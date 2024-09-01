import pandas as pd
import numpy as np

start_number = int(input('Input start index of the case number: '))
end_number = int(input('Input end index of the case number: '))

for i in range(start_number, end_number + 1):
    print(f'Processing case {i}')
    df = pd.read_csv(f'.temp/case{i}/output_uwb.csv')

    def convert_to_cartesian(distance, azimuth, elevation):
        azimuth_rad = np.radians(azimuth)
        elevation_rad = np.radians(elevation)
        
        x = (-1) * distance * np.sin(azimuth_rad)
        y = distance * np.cos(azimuth_rad)
        z = 1.0

        return x, y, z

    data_list = []
    for index, row in df.iterrows():
        x, y, z = convert_to_cartesian(row['Data1'], row['Data2'], row['Data3'])
        data_list.append({'Timestamp': row['Timestamp'], 'X': x, 'Y': y, 'Z': z})

    coordinates = pd.DataFrame(data_list)
    coordinates.to_csv(f'.temp/case{i}/data_uwb.csv', index=False)
