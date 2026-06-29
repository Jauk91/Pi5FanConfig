#!/usr/bin/with-contenv bash

# Funktion för att generera rader
write_config() {
    local MODE=$(jq --raw-output '.mode' /data/options.json)

    # Om avstängd, returnera ingenting (så att filen förblir tom på fan-inställningar)
    if [ "$MODE" == "avstängd" ]; then
        return
    fi

    # Om läget är custom, hämta allt från JSON
    if [ "$MODE" == "custom" ]; then
        T0=$(( $(jq -r '.custom_t0' /data/options.json) * 1000 ))
        H0=$(( $(jq -r '.custom_h0' /data/options.json) * 1000 ))
        S0=$(jq -r '.custom_s0' /data/options.json)
        
        T1=$(( $(jq -r '.custom_t1' /data/options.json) * 1000 ))
        H1=$(( $(jq -r '.custom_h1' /data/options.json) * 1000 ))
        S1=$(jq -r '.custom_s1' /data/options.json)
        
        T2=$(( $(jq -r '.custom_t2' /data/options.json) * 1000 ))
        H2=$(( $(jq -r '.custom_h2' /data/options.json) * 1000 ))
        S2=$(jq -r '.custom_s2' /data/options.json)
    
    # Färdiga profiler
    elif [ "$MODE" == "tyst" ]; then
        T0=60000; H0=10000; S0=75; T1=65000; H1=10000; S1=125; T2=70000; H2=10000; S2=175
    elif [ "$MODE" == "balanserad" ]; then
        T0=50000; H0=5000;  S0=100; T1=55000; H1=5000;  S1=150; T2=60000; H2=5000;  S2=200
    elif [ "$MODE" == "aggressiv" ]; then
        T0=40000; H0=2000;  S0=125; T1=45000; H1=2000;  S1=175; T2=50000; H2=2000;  S2=250
    fi

    # Skriv ut raderna
    echo "dtparam=fan_temp0=$T0,fan_temp0_hyst=$H0,fan_temp0_speed=$S0"
    echo "dtparam=fan_temp1=$T1,fan_temp1_hyst=$H1,fan_temp1_speed=$S1"
    echo "dtparam=fan_temp2=$T2,fan_temp2_hyst=$H2,fan_temp2_speed=$S2"
}

# Huvudloop
until false; do
    MODE=$(jq --raw-output '.mode' /data/options.json)
    
    for part in nvme0n1p1 mmcblk0p1 sda1 sdb1; do
        if [ -e /dev/$part ]; then
            mkdir -p /tmp/$part
            mount /dev/$part /tmp/$part 2>/dev/null
            
            if [ -e /tmp/$part/config.txt ]; then
                # Rensa gamla fläktinställningar oavsett läge
                sed -i '/dtparam=fan_temp/d' /tmp/$part/config.txt
                
                # Om inte "avstängd", skriv in de nya raderna via funktionen
                if [ "$MODE" != "avstängd" ]; then
                    write_config >> /tmp/$part/config.txt
                fi
            fi
            umount /tmp/$part 2>/dev/null
        fi
    done
    sleep 3600
done    if [ ! -e /dev/$partition ]; then
      echo "no $partition available"
      return
    fi

    umount /tmp/$partition 2>/dev/null
    mount /dev/$partition /tmp/$partition 2>/dev/null

    if [ -e /tmp/$partition/config.txt ]; then
      sed -i '/dtparam=fan_temp/d' /tmp/$partition/config.txt
      
      for line in "${fan_config_lines[@]}"; do
        if ! grep -Fxq "$line" /tmp/$partition/config.txt; then
          echo "Adding '$line' to $partition/config.txt"
          echo "$line" >> /tmp/$partition/config.txt
        else
          echo "'$line' already exists in $partition/config.txt"
        fi
      done
    else
      echo "No config.txt found on $partition"
    fi
  }

  # Process all partitions
  insertFanConfig sda1
  insertFanConfig sdb1
  insertFanConfig mmcblk0p1
  insertFanConfig nvme0n1p1

  # Find the fan device paths
  base="/sys/devices/platform/cooling_fan/hwmon"
  fan_path=""
  pwm_path=""

  for d in "$base"/hwmon*; do
      if [ -e "$d/fan1_input" ]; then
          fan_path="$d/fan1_input"
          pwm_path="$d/pwm1"
          break
      fi
  done

  echo "Fan configuration complete. Perform a hard power-off reboot TWICE to activate."
  sleep 99999
done
