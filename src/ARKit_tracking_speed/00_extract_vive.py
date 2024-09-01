import re
import os

def extract_data(log_file_path, output_file_path):
    # NTP time pattern (10-digit integer part and 5-digit decimal part)
    ntp_pattern = re.compile(r'\b\d{10}\.\d{5}\b')

    with open(log_file_path, 'r') as file:
        lines = file.readlines()

    with open(output_file_path, 'w') as output_file:
        output_file.write("Timestamp,X,Y,Z,Vx,Vy,Vz\n")
        for i in range(2, len(lines) - 1): # Skip initial two lines as headers
            # Find NTP time from current line
            match = ntp_pattern.search(lines[i])
            if match:
                timestamp = match.group()

                # Acquire x, y, z, vx, vy, vz from the next line
                next_line = lines[i + 1].strip().split(', ')
                if len(next_line) >= 9:
                    try:
                        x = next_line[3].strip()
                        y = next_line[4].strip()
                        z = next_line[5].strip()
                        vx = next_line[6].strip()
                        vy = next_line[7].strip()
                        vz = next_line[8].strip()
                        output_file.write(f"{timestamp}, {x}, {y}, {z}, {vx}, {vy}, {vz}\n")
                    except ValueError:
                        pass

case_number = input('Please enter the case number (ex. 0 for case0): ')

log_file_path = f'input/case{case_number}/VIVE.log'
output_file_path = f'.temp/case{case_number}/VIVE.csv'

if not os.path.exists('.temp'):
    os.makedirs('.temp')
if not os.path.exists(f'.temp/case{case_number}'):
    os.makedirs(f'.temp/case{case_number}')

extract_data(log_file_path, output_file_path)
