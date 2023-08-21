#!/bin/bash

# Same script as start_prod, but adopted to dev environment

# if [ -z "$ADMIN_CHAT_ID" ]; then echo "ADMIN_CHAT_ID var is blank"; else echo "ADMIN_CHAT_ID var is set to '$ADMIN_CHAT_ID'"; fi
# if [ -z "$TELEGRAM_BOT_TOKEN" ]; then echo "TELEGRAM_BOT_TOKEN var is blank"; else echo "TELEGRAM_BOT_TOKEN var is set to '$TELEGRAM_BOT_TOKEN'"; fi

arch=$(dpkg --print-architecture)

redis-cli flushall
./bin/$arch/caddy run --config CaddyfileDev &
CADDY_PID=$!
LOG_LEVEL_NAME=TRACE IS_DEV=True TIMEOUT=7 python3 -m server server &
SERVER_PID=$!

sendMessageTelegram(){
    local message=${1}

    curl -X POST \
         -H 'Content-Type: application/json' \
         -d "{\"chat_id\":\"$ADMIN_CHAT_ID\",\"text\":\"$message\"}" \
         "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"
}

while true
do
  CHECK_CADDY_PID=$(ps -A| grep $CADDY_PID |wc -l)
  if [[ $CHECK_CADDY_PID -eq 0 ]]; then
          # sendMessageTelegram "Restarting caddy, since it's down"
          ./bin/caddy start --config CaddyfileDev &
          CADDY_PID=$!
  fi

  CHECK_SERVER_PID=$(ps -A| grep $SERVER_PID |wc -l)
  if [[ $CHECK_SERVER_PID -eq 0 ]]; then
        # sendMessageTelegram "Restarting server, since it's down"
        LOG_LEVEL_NAME=TRACE TIMEOUT=7 python3 -m server server &
        SERVER_PID=%!
  fi

  sleep 15
done
