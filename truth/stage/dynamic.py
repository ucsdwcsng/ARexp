import serial
import time
from serial.tools import list_ports
import ntplib
import re
import csv

ntp_client = ntplib.NTPClient()

ntp_time_initialized = False
initial_ntp_time = None
initial_local_time = None

def extract_initial_number(s):
    match = re.search(r'\[\s*(\d+)\]', s)
    if match:
        return int(match.group(1))
    else:
        return None

def extract_last_number(s):
    match = re.search(r'\[(-?\d+)\]$', s)
    if match:
        return int(match.group(1))
    else:
        return None

def get_ntp_time():
    global ntp_time_initialized, initial_ntp_time, initial_local_time
    if not ntp_time_initialized:
        try:
            response = ntp_client.request('pool.ntp.org')
            initial_ntp_time = response.tx_time
            initial_local_time = time.time()
            ntp_time_initialized = True
            return initial_ntp_time
        except Exception as e:
            print(e)
            return 'NTP time fetch failed'
    else:
        current_time = initial_ntp_time + (time.time() - initial_local_time)
        return current_time

# List and select the serial port
ports = list_ports.comports()
for i, port in enumerate(ports):
    print(f"{i}: {port}")
port_index = int(input("input number: "))
selected_port = ports[port_index].device

# Open the serial connection
ser = serial.Serial(selected_port, 38400, timeout=0.1)
time.sleep(2)

def finish_move():
    line = ser.readline()
    if line:
        decoded_line = line.decode('utf-8').strip()
        if 'Move[0601][Absolute]' in decoded_line:
            coordinates = extract_last_number(decoded_line)
            return coordinates
        else:
            return None
    else:
        return None

def dump_response(ser):
    while True:
        response = ser.readline()
        if response:
            print(response)
        else:
            break

def extract_initial_coordinates(ser):
    while True:
        line = ser.readline()
        if line:
            decoded_line = line.decode('utf-8').strip()
            if 'Position_x' in decoded_line:
                coordinates = extract_initial_number(decoded_line)
                return coordinates

with open('output.csv', 'w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(['Event', 'Time', 'X Coordinate'])

    try:
        ser.write(b'sta\n')
        time.sleep(100)  # Wait for the device to respond
        dump_response(ser)
        time.sleep(1)

        ser.write(b'pox\n')
        time.sleep(1)
        current_x = extract_initial_coordinates(ser)
        time.sleep(1)

        while True:
            timestamp = get_ntp_time()
            writer.writerow(['Start leaving', timestamp, current_x])
            print(f'Start leaving at {timestamp}, x: {current_x}')
            ser.write(b'max 400\n')
            time.sleep(5)

            while True:
                coordinates = finish_move()
                if coordinates is not None:
                    timestamp = get_ntp_time()
                    writer.writerow(['Finish leaving', timestamp, coordinates])
                    print(f'Finish leaving at {timestamp}, x: {coordinates}')
                    current_x = coordinates
                    break
            time.sleep(4)

            timestamp = get_ntp_time()
            writer.writerow(['Start coming back', timestamp, current_x])
            print(f'Start coming back at {timestamp}, x: {current_x}')
            ser.write(b'max 0\n')
            time.sleep(5)

            while True:
                coordinates = finish_move()
                if coordinates is not None:
                    timestamp = get_ntp_time()
                    writer.writerow(['Finish coming back', timestamp, coordinates])
                    print(f'Finish coming back at {timestamp}, x: {coordinates}')
                    current_x = coordinates
                    break
            time.sleep(4)

    except Exception as e:
        print("An error occurred:", e)

    finally:
        ser.close()
