# Sane Machine: Quick Summary

Here is the simple breakdown of how everything works:

### What are we measuring? (Parameters)
*   **Vibration**: We watch how much the machine shakes to find loose parts or drum issues.
*   **Electricity (Amps)**: we track how hard the motor is pulling power to see if it’s overworking.
*   **Total Energy (Watts)**: We use this to check if the heater is working or if the motor is overheating.

### How do we decide the status? (Calculation)
*   **Healthy**: If all the sensor levels stay within normal, safe zones.
*   **Warning**: If the shaking or power is a little high, but not dangerous yet.
*   **Failure**: If the vibration hits 3.5x its normal limit, or if the electricity spikes dangerously.
*   **Logic**: Our "Brain" knows that faster machines (high RPM) shake more, so it automatically adjusts the limits for each specific model.

### Where is the data? (Storage)
*   **The Archive**: Thousands of seconds of real sensor recordings are stored in `.csv` files inside the `assets` folder.
*   **The History**: The records of your tests are saved in the app's temporary memory while it's running.
*   **The App**: The technical "rules" for each machine are kept in the `CatalogService` code.

---

### 🏛️ The Three Main Services (The "Parts" of the System)

If you look at the code, everything is organized into three main "Services" that work together:

1.  **Catalog Service (The Library)**:
    *   This is where we store all the "specs" for different washing machines. 
    *   It knows that an *LG T70* has a 700 RPM limit, while an *IFB Senator* has 1400 RPM. 
    *   Think of it like a **Technical Encyclopedia** for every machine the app supports.

2.  **Archive Service (The Data Courier)**:
    *   This part does the "grunt work" of reading the huge sensor files (the CSVs). 
    *   It opens the files, pulls out the vibration and electricity numbers, and hands them over to the app. 
    *   It’s like a **Technical Scout** that goes and gets the raw facts from the machine's records.

3.  **Maintenance Service (The Doctor)**:
    *   This is the real **"Brain"** of the project. 
    *   It takes the numbers from the Archive and the specs from the Catalog and uses math (the RPM formula) to give you a diagnosis. 
    *   It’s the part that actually says "Help! This machine is about to break!"
