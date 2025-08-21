#!/usr/bin/env -S bash

# A Bash script to monitor system stats and output them in JSON format.

# --- Configuration ---
# Default sleep duration in seconds. Can be overridden by the first argument.
SLEEP_DURATION=3

# --- Argument Parsing ---
# Check if a command-line argument is provided for the sleep duration.
if [[ -n "$1" ]]; then
  # Basic validation to ensure the argument is a number (integer or float).
  if [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    SLEEP_DURATION=$1
  else
    # Output to stderr if the format is invalid.
    echo "Warning: Invalid duration format '$1'. Using default of ${SLEEP_DURATION}s." >&2
  fi
fi

# --- Global Cache Variables ---
# These variables will store the discovered CPU temperature sensor path and type
# to avoid searching for it on every loop iteration.
TEMP_SENSOR_PATH=""
TEMP_SENSOR_TYPE=""

# --- Data Collection Functions ---

#
# Gets memory usage in GB, MB, and as a percentage.
#
get_memory_info() {
  awk '
    /MemTotal/ {total=$2}
    /MemAvailable/ {available=$2}
    END {
      if (total > 0) {
        usage_kb = total - available
        usage_gb = usage_kb / 1000000
        usage_percent = (usage_kb / total) * 100
        printf "%.1f %.0f\n", usage_gb, usage_percent
      } else {
        # Fallback if /proc/meminfo is unreadable or empty.
        print "0.0 0 0"
      }
    }
  ' /proc/meminfo
}

#
# Gets the usage percentage of the root filesystem ("/").
#
get_disk_usage() {
  # df gets disk usage. --output=pcent shows only the percentage for the root path.
  # tail -1 gets the data line, and tr removes the '%' sign and whitespace.
  df --output=pcent / | tail -1 | tr -d ' %'
}

#
# Calculates current CPU usage over a short interval.
#
get_cpu_usage() {
  # Read all 10 CPU time fields to prevent errors on newer kernels.
  read -r cpu prev_user prev_nice prev_system prev_idle prev_iowait prev_irq prev_softirq prev_steal prev_guest prev_guest_nice < /proc/stat
  
  # Calculate previous total and idle times.
  local prev_total_idle=$((prev_idle + prev_iowait))
  local prev_total=$((prev_user + prev_nice + prev_system + prev_idle + prev_iowait + prev_irq + prev_softirq + prev_steal + prev_guest + prev_guest_nice))
  
  # Wait for a short period.
  sleep 0.05
  
  # Read all 10 CPU time fields again for the second measurement.
  read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
  
  # Calculate new total and idle times.
  local total_idle=$((idle + iowait))
  local total=$((user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice))
  
  # Add a check to prevent division by zero if total hasn't changed.
  if (( total <= prev_total )); then
      echo "0.0"
      return
  fi

  # Calculate the difference over the interval.
  local diff_total=$((total - prev_total))
  local diff_idle=$((total_idle - prev_total_idle))

  # Use awk for floating-point calculation and print the percentage.
  awk -v total="$diff_total" -v idle="$diff_idle" '
    BEGIN {
      if (total > 0) {
        # Formula: 100 * (Total - Idle) / Total
        usage = 100 * (total - idle) / total
        printf "%.1f\n", usage
      } else {
        print "0.0"
      }
    }'
}

#
# Finds and returns the CPU temperature in degrees Celsius.
# Caches the sensor path for efficiency.
#
get_cpu_temp() {
  # If the sensor path hasn't been found yet, search for it.
  if [[ -z "$TEMP_SENSOR_PATH" ]]; then
    for dir in /sys/class/hwmon/hwmon*; do
      # Check if the 'name' file exists and read it.
      if [[ -f "$dir/name" ]]; then
        local name
        name=$(<"$dir/name")
        # Check for supported sensor types.
        if [[ "$name" == "coretemp" || "$name" == "k10temp" || "$name" == "zenpower" ]]; then
          TEMP_SENSOR_PATH=$dir
          TEMP_SENSOR_TYPE=$name
          break # Found it, no need to keep searching.
        fi
      fi
    done
  fi

  # If after searching no sensor was found, return 0.
  if [[ -z "$TEMP_SENSOR_PATH" ]]; then
    echo 0
    return
  fi

  # --- Get temp based on sensor type ---
  if [[ "$TEMP_SENSOR_TYPE" == "coretemp" ]]; then
    # For Intel 'coretemp', average all available temperature sensors.
    local total_temp=0
    local sensor_count=0

    # Use a for loop with a glob to iterate over all temp input files.
    # This is more efficient than 'find' for this simple case.
    for temp_file in "$TEMP_SENSOR_PATH"/temp*_input; do
      # The glob returns the pattern itself if no files match,
      # so we must check if the file actually exists.
      if [[ -f "$temp_file" ]]; then
        total_temp=$((total_temp + $(<"$temp_file")))
        sensor_count=$((sensor_count + 1))
      fi
    done

    if (( sensor_count > 0 )); then
      # Use awk for the final division to handle potential floating point numbers
      # and convert from millidegrees to integer degrees Celsius.
      awk -v total="$total_temp" -v count="$sensor_count" 'BEGIN { print int(total / count / 1000) }'
    else
      # If no sensor files were found, return 0.
      echo 0
    fi

  elif [[ "$TEMP_SENSOR_TYPE" == "k10temp" ]]; then
    # For AMD 'k10temp', find the 'Tctl' sensor, which is the control temperature.
    local tctl_input=""
    for label_file in "$TEMP_SENSOR_PATH"/temp*_label; do
      if [[ -f "$label_file" ]] && [[ $(<"$label_file") == "Tctl" ]]; then
        # The input file has the same name but with '_input' instead of '_label'.
        tctl_input="${label_file%_label}_input"
        break
      fi
    done

    if [[ -f "$tctl_input" ]]; then
      # Read the temperature and convert from millidegrees to degrees.
      echo "$(( $(<"$tctl_input") / 1000 ))"
    else
      echo 0 # Fallback
    fi
  elif [[ "$TEMP_SENSOR_TYPE" == "zenpower" ]]; then
          # For zenpower, read the first available temp sensor
          for temp_file in "$TEMP_SENSOR_PATH"/temp*_input; do
                  if [[ -f "$temp_file" ]]; then
                          local temp_value
                          temp_value=$(cat "$temp_file" | tr -d '\n\r') # Remove any newlines
                          echo "$((temp_value / 1000))"
                          return
                  fi
          done
          echo 0

          if [[ -f "$tctl_input" ]]; then
                  # Read the temperature and convert from millidegrees to degrees.
                  echo "$(($(<"$tctl_input") / 1000))"
          else
                  echo 0 # Fallback
          fi
  else
    echo 0 # Should not happen if cache logic is correct.
  fi
}

# --- Main Loop ---
# This loop runs indefinitely, gathering and printing stats.
while true; do
  # Call the functions to gather all the data.
  # get_memory_info
  read -r mem_gb mem_per <<< "$(get_memory_info)"
  
  # Command substitution captures the single output from the other functions.
  disk_per=$(get_disk_usage)
  cpu_usage=$(get_cpu_usage)
  cpu_temp=$(get_cpu_temp)

  # Use printf to format the final JSON output string, adding the mem_mb key.
  printf '{"cpu": "%s", "cputemp": "%s", "memgb":"%s", "memper": "%s", "diskper": "%s"}\n' \
    "$cpu_usage" \
    "$cpu_temp" \
    "$mem_gb" \
    "$mem_per" \
    "$disk_per"

  # Wait for the specified duration before the next update.
  sleep "$SLEEP_DURATION"
done
