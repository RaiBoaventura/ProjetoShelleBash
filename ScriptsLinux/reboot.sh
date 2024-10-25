#!/bin/bash

# Configuração do log
LOG_FILE="Caminho/Para/Logs/service_verification.log"

# Função para escrever no log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Script para reiniciar o servidor
log "Preparando para reiniciar o servidor..."

# Reinicia o servidor sem solicitar senha
sudo reboot &
log "O servidor será reiniciado em breve."

# Acompanhando o processo de reboot
sleep 10
log "Acompanhando o processo de reboot..."
while systemctl is-active --quiet; do
    sleep 5  # Verifica a cada 5 segundos se o servidor ainda está ativo
done
log "O servidor foi reiniciado."
