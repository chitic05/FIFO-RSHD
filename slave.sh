#!/bin/bash
# slave.sh

source ./config

ID=$1 # argumentul 1 este numarul sclavului
PIPE="${SLAVE_FIFO_PREFIX}${ID}"

echo "[Slave ${ID}] Initializat."

# Deschidem pipe-ul sclavului
# Folosim tot <> pentru a nu se inchide sclavul daca serverul intarzie scrierea
exec 3<>"$PIPE"

while read -r request <&3; do
    # Verificam formatul cu Regex
    if [[ "$request" =~ BEGIN-REQ\ \[([0-9]+):\ (.*)\]\ END-REQ ]]; then
        client_pid="${BASH_REMATCH[1]}"
        cmd="${BASH_REMATCH[2]}"
        
        # Construim calea catre FIFO-ul clientului folosind config
        client_fifo="${CLIENT_FIFO_PREFIX}${client_pid}"

        echo "[Slave $ID] Procesez comanda '$cmd' pentru client $client_pid"

        if [ -p "$client_fifo" ]; then
            # Executam comanda si trimitem output-ul (si erorile) in pipe-ul clientului
            eval "$cmd" > "$client_fifo" 2>&1
        else
            echo "[Slave $ID] EROARE: FIFO client lipsa ($client_fifo)"
        fi
    fi
done
