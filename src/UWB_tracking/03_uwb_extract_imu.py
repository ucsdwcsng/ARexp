import pandas as pd

def align_imu(case_num):
    input_csv_paths = [f'.temp/case{case_num}/output_acc.csv', f'.temp/case{case_num}/output_gyro.csv', f'.temp/case{case_num}/output_mag.csv']  # 入力CSVファイルのパスリスト
    output_csv_paths = [f'.temp/case{case_num}/data_acc.csv', f'.temp/case{case_num}/data_gyro.csv', f'.temp/case{case_num}/data_mag.csv']  # 出力CSVファイルのパスリスト

    for input_path, output_path in zip(input_csv_paths, output_csv_paths):
        df = pd.read_csv(input_path)
        df.drop(columns=['Data_type'], inplace=True)
        df.to_csv(output_path, index=False)

start_number = int(input('Input start index of the case number: '))
end_number = int(input('Input end index of the case number: '))

for i in range(start_number, end_number + 1):
    print(f'Processing case {i}')
    align_imu(i)
