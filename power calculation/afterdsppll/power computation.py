import pandas as pd

def calculate_average_power(csv_file, voltage_level):
    # Load the CSV file, skip the first 10 rows
    data = pd.read_csv(csv_file, skiprows=10)
    # Get the second column 
    current = data.iloc[:, 1]
    # Calculate the instantaneous power
    power = abs(current) * voltage_level
    # Calculate the average power
    average_power = power.mean()
    return average_power

csv_File = "0_128_0_49.csv"
voltage_level = 3.3
print(calculate_average_power(csv_File, voltage_level))