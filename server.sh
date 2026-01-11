#!/bin/bash
# server.sh

source ./config  

# Sterge tmp si termina procesele 
trap "rm -rf ./tmp; kill 0" SIGINT EXIT

# Cream directorul tmp daca nu exista
if [ ! -d "$BASE_DIR" ]; then
    mkdir -p "$BASE_DIR"
fi

# Creare FIFO-MAIN
if [ ! -p "$MAIN_FIFO" ]; then
    mkfifo "$MAIN_FIFO"
fi

echo "Server pornit. Se initializeaza $NUM_SLAVES sclavi..."

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

# Deschidem pipe-ul in mod Read+Write (<>)
exec 3<>"$MAIN_FIFO"

echo "Astept comenzi..."
# Citeste din canalul 3 (e custom)
while read -r line <&3; do
    [ -z "$line" ] && continue

    slave_id=$((counter % NUM_SLAVES))
    target_pipe="${SLAVE_FIFO_PREFIX}${slave_id}"

    # Folosim & pentru a nu bloca bucla principala
    echo "$line" > "$target_pipe" &

    counter=$((counter + 1))
done
