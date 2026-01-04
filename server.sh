#!/bin/bash
# server.sh

source ./config  

# Curatare la Ctrl+C kill 0 omoara procesele create de acest script
trap "rm -r -f tmp; kill 0" SIGINT
trap "rm -rf tmp; kill 0" EXIT

mkdir tmp

# Creare FIFO-MAIN
if [ ! -p "$MAIN_FIFO" ]; then
    mkfifo "$MAIN_FIFO"
fi

# Pregatim sclavii
for ((i=0; i<NUM_SLAVES; i++)); do
    # Facem PIPE-ul server->slave
    slave_pipe="${SLAVE_FIFO_PREFIX}${i}"
    if [ ! -p "$slave_pipe" ]; then
        mkfifo "$slave_pipe"
    fi
    
    # Pornim sclavul
    ./slave.sh $i & 
done

counter=0

# tail -f citeste continuu din FIFO-MAIN
tail -f "$MAIN_FIFO" | while read -r line; do
    if [ -n "$line" ]; then
        slave_id=$((counter % NUM_SLAVES))
        target_pipe="${SLAVE_FIFO_PREFIX}${slave_id}"
        
        
        # Trimitem linia catre sclav
        echo "$line" > "$target_pipe" &
        
        counter=$((counter + 1))
    fi
done
