import time
import csv
from datetime import datetime

file = "sensor_data.csv"

with open(file, "a", newline="") as f:
    writer = csv.writer(f)

    if f.tell() == 0:
        writer.writerow(["Date/Time", "MAX6675_Temp", "SHT30_Temp", "Humidity"])

    while True:
        writer.writerow([
            datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "TEST",
            "TEST",
            "TEST"
        ])
        f.flush()

        print("Data saved:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        time.sleep(2)
