#!/usr/bin/with-contenv bash

# Funktion för att bygga konfigurationen
write_config() {
    local MODE=$(jq --raw-output '.mode' /data/options.json)
    
    if [ "$MODE" == "avstängd" ]; then return; fi

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
    elif [ "$MODE" == "tyst" ]; then
        T0=60000; H0=10000; S0=75; T1=65000; H1=10000; S1=125; T2=70000; H2=10000; S2=175
    elif [ "$MODE" == "balanserad" ]; then
        T0=50000; H0=5000; S0=100; T1=55000; H1=5000; S1=150; T2=60000; H2=5000; S2=200
    elif [ "$MODE" == "aggressiv" ]; then
        T0=40000; H0=2000; S0=125; T1=45000; H1=2000; S1=175; T2=50000; H2=2000; S2=250
    fi

    # Returnera raderna till anroparen
    echo "dtparam=fan_temp0=$T0,fan_temp0_hyst=$H0,fan_temp0_speed=$S0"
    echo "dtparam=fan_temp1=$T1,fan_temp1_hyst=$H1,fan_temp1_speed=$S1"
    echo "dtparam=fan_temp2=$T2,fan_temp2_hyst=$H2,fan_temp2_speed=$S2"
}

# Huvudloop
until false; do
    MODE=$(jq --raw-output '.mode' /data/options.json)
    CONFIG_LINES=$(write_config)

    for part in nvme0n1p1 mmcblk0p1 sda1 sdb1; do
        if [ -e /dev/$part ]; then
            mkdir -p /tmp/$part
            mount /dev/$part /tmp/$part 2>/dev/null
            if [ -e /tmp/$part/config.txt ]; then
                sed -i '/dtparam=fan_temp/d' /tmp/$part/config.txt
                if [ "$MODE" != "avstängd" ]; then
                    echo "$CONFIG_LINES" >> /tmp/$part/config.txt
                fi
                echo "Uppdaterade $part/config.txt med läge: $MODE"
            fi
            umount /tmp/$part 2>/dev/null
        fi
    done
    sleep 3600
done
