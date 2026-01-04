#!/bin/bash
# slave.sh

source ./config

ID=$1 #argumentul 1 este numarul sclavului
PIPE="${SLAVE_FIFO_PREFIX}${ID}"

echo "Slave ${ID} initializat"

while true; do
    if read request < "$PIPE"; then
        
        # [[]] si =~ ne permite sa folosim comparatie cu regex si () face o capturare ce se salveaza in BASH_REMATCH[INDEX]
        if [[ "$request" =~ BEGIN-REQ\ \[([0-9]+):\ (.*)\]\ END-REQ ]]; then
            
            client_pid="${BASH_REMATCH[1]}"
            cmd="${BASH_REMATCH[2]}"
            
            client_fifo="${CLIENT_FIFO_PREFIX}${client_pid}"
            
            # -p verifica daca exista fifo ul respectiv
            if [ -p "$client_fifo" ]; then
                # eval executa comanda $cmd cu toate caracterele

                eval "$cmd" > "$client_fifo" 2>&1 # 2>&1 redirectioneaza erorile stderr in fifo ul $client_fifo
            else
                echo "[Slave $ID] EROARE: Nu gasesc pipe-ul pentru clientul ${client_pid}"
            fi

        fi
    fi
done
