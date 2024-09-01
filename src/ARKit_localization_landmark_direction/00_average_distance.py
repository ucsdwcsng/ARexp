import os
import glob
import numpy as np
import csv

def process_files(input_directory, output_file):
    distances = []
    for filepath in glob.glob(os.path.join(input_directory, 'ARKitData_*.csv')):
        print(filepath)
        with open(filepath, 'r') as file:
            reader = csv.reader(file)
            next(reader)  # Skip the header
            for row in reader:
                distance = float(row[1])
                distances.append(distance)
    
    if distances:
        average_distance = np.mean(distances)
        print(f'Average distance: {average_distance}')
        # Write the average distance to the output CSV file
        with open(output_file, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(['Average Distance'])
            writer.writerow([average_distance])
    else:
        print('No data available to calculate distance.')

start_number = int(input('Input start index of the case number: '))
end_number = int(input('Input end index of the case number: '))


for i in range(start_number, end_number + 1):
    print(f'Processing case {i}')

    input_case_dir = f'input/case{i}'
    output_case_dir = f'output/case{i}'
    if not os.path.exists(output_case_dir):
        os.makedirs(output_case_dir)
        
    output_csv_file = os.path.join(output_case_dir, 'result.csv')  # Your output CSV file path here

    # Call the processing function
    process_files(input_case_dir, output_csv_file)
