# Function to convert millidegree Celsius to Celsius
convert_to_c() {
    local temp_milli_c=$1
    # Convert millidegree Celsius to Celsius
    local temp=$temp_milli_c/1000
    echo "scale=2; $temp" | bc
}

# Main loop to continuously monitor the temperature
while true; do
    clear
    echo "Monitoring Coral PCIe Accelerators Temperature in Celsius"

    # Dynamically find all apex devices and read their temperatures
    for device_path in /sys/class/apex/apex_*; do
        if [ -f "$device_path/temp" ]; then
            device_name=$(basename "$device_path")
            temp_milli_c=$(cat "$device_path/temp")

            temp_c=$(convert_to_c $temp_milli_c)
            echo "$device_name: $temp_c°C"
        else
            echo "$device_name: Temperature readout not available"
        fi
    done

    # Wait for a second before the next update
    sleep 1
done
