#!/bin/bash
# client.sh

source ./config

if [ -z "$1" ]; then
    echo "Utilizare: $0 <comanda_de_executat>"
    echo "Exemplu: $0 'ls -l | head -5'"
    exit 1
fi

COMMAND="$@"
CLIENT_PID=$$

# Construim numele FIFO folosind prefixul din config
REPLY_FIFO="${CLIENT_FIFO_PREFIX}${CLIENT_PID}"

# Facem FIFO-ul clientului 
if [ ! -p "$REPLY_FIFO" ]; then
    mkfifo "$REPLY_FIFO"
fi

# Curatare la iesire
trap "rm -f $REPLY_FIFO" EXIT

REQUEST_MSG="BEGIN-REQ [${CLIENT_PID}: ${COMMAND}] END-REQ"

if [ -p "$MAIN_FIFO" ]; then
    # Scriem in FIFO-ul serverului
    echo "$REQUEST_MSG" > "$MAIN_FIFO"
else
    echo "Eroare: Serverul nu este pornit (Nu gasesc $MAIN_FIFO)."
    exit 1
fi

echo "[Client ${CLIENT_PID}] Am trimis comanda. Astept rezultatul..."
echo "---------------- REZULTAT SERVER ----------------"

# 'cat' va bloca executia pana cand serverul (sclavul) scrie in FIFO
cat "$REPLY_FIFO"
