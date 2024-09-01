import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

start_number = int(input('Input start index of the case number: '))
end_number = int(input('Input end index of the case number: '))

statistics = []

if not os.path.exists('output'):
    os.makedirs('output')

for i in range(start_number, end_number + 1):
    print(f'Processing case {i}')

    input_csv_truth = f'.temp/case{i}/resampled_truth.csv'
    if os.path.exists(f'.temp/case{i}/resampled_arkit.csv'):
        input_csv_data = f'.temp/case{i}/resampled_arkit.csv'
    else:
        input_csv_data = None

    if not os.path.exists(f'output/case{i}'):
        os.makedirs(f'output/case{i}')

    df_truth = pd.read_csv(input_csv_truth)
    df_data = pd.read_csv(input_csv_data)

    num_data = len(df_data)
    time_array = np.linspace(0, num_data / 60, num_data)
    
    fig, ax = plt.subplots()
    ax.set_xlabel('Time [s]')
    ax.set_ylabel('Error [m]')
    ax.set_xlim(0, 105)
    ax.set_xticks([0, 20, 40, 60, 80, 100])

    error = ((df_data['X'][:num_data] - df_truth['X'][:num_data])**2 + 
             (df_data['Y'][:num_data] - df_truth['Y'][:num_data])**2 + 
             (df_data['Z'][:num_data] - df_truth['Z'][:num_data])**2)**0.5
    plt.plot(time_array, error)
    plt.tight_layout()

    max_error = error.max()
    min_error = error.min()
    mean_error = error.mean()
    var_error = error.var()
    std_error = error.std()
    percentile_99_error = np.percentile(error, 99)

    statistics.append({
        'Max': max_error,
        'Min': min_error,
        'Mean': mean_error,
        'Variance': var_error,
        'Standard Deviation': std_error,
        '99th Percentile': percentile_99_error
    })

    df_statistics = pd.DataFrame(statistics)
    plt.savefig(f'output/case{i}/error_timeline.png')
    plt.close(fig)

    output_csv_error_timeline = f'output/case{i}/error_timeline.csv'
    output_csv_error_statistics = f'output/case{i}/error_statistics.csv'
    error.to_csv(output_csv_error_timeline, index=False)
    df_statistics.to_csv(output_csv_error_statistics, index=False)
