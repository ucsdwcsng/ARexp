import os
import csv
import numpy as np
import re

def calculate_euclidean_error(x, y, z, true_x, true_y, true_z):
    return np.sqrt((x - true_x) ** 2 + (y - true_y) ** 2 + (z - true_z) ** 2)

def extract_case_number(case_name):
    match = re.search(r'(\d+)', case_name)
    return match.group(0) if match else None

def load_truth_coordinates(truth_file, case_num):
    truth_coordinates = [0, 0, 0]
    with open(truth_file, mode='r') as file:
        csv_reader = csv.reader(file)
        next(csv_reader)  # Skip the header
        for row in csv_reader:
            if int(row[0]) == case_num:
                distance_m = float(row[3]) / 100  # Convert cm to m
                truth_coordinates[2] = distance_m
                break  # Stop reading after finding the case number
    return truth_coordinates

def process_case_files(case_num, truth_coordinates, output_file):
    distance_sum = 0
    x_sum = 0
    y_sum = 0
    z_sum = 0

    for i in range(10):
        file_path = os.path.join(f'input/case{case_num}', f'ARKitData_{i}.csv')
        try:
            with open(file_path, 'r') as file:
                csv_reader = csv.reader(file)
                next(csv_reader)  # Skip header
                data = next(csv_reader)  # Read second line
                x, y, z = float(data[2]), float(data[3]), float(data[4])
                error = calculate_euclidean_error(x, y, z, truth_coordinates[0], truth_coordinates[1], truth_coordinates[2])
                distance_sum += error
                x_sum += x
                y_sum += y
                z_sum += z
        except FileNotFoundError:
            print(f'File not found: {file_path}')
            continue

    average_error = distance_sum / 10
    average_x = x_sum / 10
    average_y = y_sum / 10
    average_z = z_sum / 10

    with open(output_file, 'w', newline='') as file:
        csv_writer = csv.writer(file)
        csv_writer.writerow(['case', 'average_error', 'average_x', 'average_y', 'average_z'])  # Write header
        csv_writer.writerow([case_num, average_error, average_x, average_y, average_z])  # Write results directly

# Ensure the output directory exists
input_directory = 'input'
truth_file = 'input/cases.csv'  # Path to the truth coordinates file
output_directory = 'output'

if not os.path.exists(output_directory):
    os.makedirs(output_directory)

start_number = int(input('Input start index of the case number: '))
end_number = int(input('Input end index of the case number: '))

for i in range(start_number, end_number + 1):
    print(f'Processing case {i}')

    input_case_dir = f'input/case{i}'
    output_case_dir = f'output/case{i}'
    if not os.path.exists(output_case_dir):
        os.makedirs(output_case_dir)
        
    output_csv_file = os.path.join(output_case_dir, 'result.csv')  # Your output CSV file path here

    # Load truth coordinates
    truth_coordinates = load_truth_coordinates(truth_file, i)

    # Call the processing function
    process_case_files(i, truth_coordinates, output_csv_file)
