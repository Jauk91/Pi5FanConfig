#! /usr/bin/with-contenv bash 
whoami 
id 
echo $0 

# Webbservern (måste finnas kvar för att tillägget ska vara aktivt)
nc -lk -p 8099 -e  echo -e 'HTTP/1.1 200 OK\r\nServer: DeskPiPro\r\nDate:$(date)\r\nContent-Type: text/html; charset=UTF8\r\nCache-Control: no-store, no cache, must-revalidate\r\n\r\n<!DOCTYPE html><html><body><p>HassOS Pi 5 Fan Enabler WebUI.</p></body></html>\r\n\n\n' &

# Huvudloop
until false; do
  # 1. Hämta läge
  MODE=$(jq --raw-output '.mode' /data/options.json)
  
  # 2. Definiera rader baserat på VALFRITT läge
  if [ "$MODE" == "tyst" ]; then
      fan_config_lines=("dtparam=fan_temp0=60000,fan_temp0_hyst=10000,fan_temp0_speed=75" "dtparam=fan_temp1=65000,fan_temp1_hyst=10000,fan_temp1_speed=125" "dtparam=fan_temp2=70000,fan_temp2_hyst=10000,fan_temp2_speed=175")
  elif [ "$MODE" == "balanserad" ]; then
      fan_config_lines=("dtparam=fan_temp0=50000,fan_temp0_hyst=5000,fan_temp0_speed=100" "dtparam=fan_temp1=55000,fan_temp1_hyst=5000,fan_temp1_speed=150" "dtparam=fan_temp2=60000,fan_temp2_hyst=5000,fan_temp2_speed=200")
  elif [ "$MODE" == "aggressiv" ]; then
      fan_config_lines=("dtparam=fan_temp0=40000,fan_temp0_hyst=2000,fan_temp0_speed=125" "dtparam=fan_temp1=45000,fan_temp1_hyst=2000,fan_temp1_speed=175" "dtparam=fan_temp2=50000,fan_temp2_hyst=2000,fan_temp2_speed=250")
  elif [ "$MODE" == "custom" ]; then
      T0=$(( $(jq -r '.custom_t0' /data/options.json) * 1000 )); H0=$(( $(jq -r '.custom_h0' /data/options.json) * 1000 )); S0=$(jq -r '.custom_s0' /data/options.json)
      T1=$(( $(jq -r '.custom_t1' /data/options.json) * 1000 )); H1=$(( $(jq -r '.custom_h1' /data/options.json) * 1000 )); S1=$(jq -r '.custom_s1' /data/options.json)
      T2=$(( $(jq -r '.custom_t2' /data/options.json) * 1000 )); H2=$(( $(jq -r '.custom_h2' /data/options.json) * 1000 )); S2=$(jq -r '.custom_s2' /data/options.json)
      fan_config_lines=("dtparam=fan_temp0=$T0,fan_temp0_hyst=$H0,fan_temp0_speed=$S0" "dtparam=fan_temp1=$T1,fan_temp1_hyst=$H1,fan_temp1_speed=$S1" "dtparam=fan_temp2=$T2,fan_temp2_hyst=$H2,fan_temp2_speed=$S2")
  else
      fan_config_lines=() # Avstängd eller okänt läge
  fi

  # 3. Funktion för att skriva till config.txt
  insertFanConfig () {
    partition=$1
    if [ ! -e /dev/$partition ]; then return; fi
    umount /tmp/$partition 2>/dev/null
    mount /dev/$partition /tmp/$partition 2>/dev/null
    if [ -e /tmp/$partition/config.txt ]; then
      sed -i '/dtparam=fan_temp/d' /tmp/$partition/config.txt
      for line in "${fan_config_lines[@]}"; do
          echo "$line" >> /tmp/$partition/config.txt
      done
    fi
    umount /tmp/$partition 2>/dev/null
  }

  # Kör för alla partitioner
  insertFanConfig sda1; insertFanConfig sdb1; insertFanConfig mmcblk0p1; insertFanConfig nvme0n1p1

  # Fläktens sökvägar (ditt original-block)
  base="/sys/devices/platform/cooling_fan/hwmon"
  for d in "$base"/hwmon*; do
      if [ -e "$d/fan1_input" ]; then fan_path="$d/fan1_input"; pwm_path="$d/pwm1"; break; fi
  done

  sleep 300
done
