#!/bin/bash
# client.sh

source ./config

if [ -z "$1" ]; then
    echo "Utilizare: $0 <comanda_de_executat>"
    echo "Exemplu: $0 'ls -l | head -5'"
    exit 1
fi

COMMAND="$@"      #toate comenzile date ca argumente 
CLIENT_PID=$$         # $$ este PID-ul clientului
REPLY_FIFO="tmp/server-reply-${CLIENT_PID}"

#Facem FIFO-ul clientului 
if [ ! -p "$REPLY_FIFO" ]; then
    mkfifo "$REPLY_FIFO"
fi


trap "rm -f $REPLY_FIFO" EXIT # daca scriptul se termina, indiferent de modalitate, se sterge FIFO-ul


REQUEST_MSG="BEGIN-REQ [${CLIENT_PID}: ${COMMAND}] END-REQ"

if [ -p "$MAIN_FIFO" ]; then
    # Scriem in FIFO-ul serverului
    echo "$REQUEST_MSG" > "$MAIN_FIFO"
else
    echo "Eroare: Serverul nu este pornit."
    exit 1
fi

echo "[Client ${CLIENT_PID}] Astept rezultatul..."
echo "---------------- REZULTAT SERVER ----------------"

# 'cat' va bloca executia pana cand serverul incepe sa scrie in FIFO
cat "$REPLY_FIFO"