import pandas as pd
import os

start_number = int(input('Input start index of the case number: '))
end_number = int(input('Input end index of the case number: '))

for i in range(start_number, end_number + 1):
    print(f'Processing case {i}')

    input_csv_path = f'input/case{i}/localization.csv'
    output_base_path = 'output_'

    df = pd.read_csv(input_csv_path)
    df = df[df['Timestamp'] != 0]

    for data_type in ['mag', 'acc', 'gyro', 'uwb']:
        # Filter for specific data type
        df_filtered = df[df.iloc[:, 1] == data_type]
        
        # Select only the columns you need (here we assume the first 5 columns)
        df_filtered = df_filtered.iloc[:, :5]  # Select first 5 columns
        
        # Set new column names
        new_columns = ['Timestamp', 'Data_type', 'Data1', 'Data2', 'Data3']
        df_filtered.columns = new_columns
        
        # Remove the first row (if needed)
        df_filtered = df_filtered.iloc[1:, :]
        
        # Define folder path
        folder_path = f'.temp/case{i}'
        
        # If no folder specified, create it
        if not os.path.exists(folder_path):
            os.makedirs(folder_path)

        # Save filtered data frame to CSV
        output_path = f'.temp/case{i}/{output_base_path}{data_type}.csv'
        df_filtered.to_csv(output_path, index=False)
