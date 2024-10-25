#!/bin/bash

# Configuração do log
LOG_FILE="Caminho/Para/Logs/service_verification.log"
REBOOT_SCRIPT="Caminho/Para/Scripts/reboot.sh"  # Caminho para o script de reboot

# Função para escrever no log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Função para verificar se os serviços estão em execução
check_services() {
    local SERVICES=("$@")  # Recebe a lista de serviços como argumento

    for service in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log "O serviço '$service' está em execução. Aguardando sua finalização..."
            while systemctl is-active --quiet "$service"; do
                sleep 5
            done
            log "O serviço '$service' foi finalizado."
        else
            log "O serviço '$service' não está em execução."
        fi
    done
}

# Lista de serviços a verificar
SERVICES_TO_CHECK=("nome_servico1" "nome_servico2" "firebird")  # Substitua pelos nomes reais dos serviços que deseja verificar

# Chama a função para verificar os serviços
check_services "${SERVICES_TO_CHECK[@]}"

# Verifica se algum dos serviços relacionados ainda está ativo
active_services=0
for service in "${SERVICES_TO_CHECK[@]}"; do
    if systemctl is-active --quiet "$service"; then
        active_services=1
        break
    fi
done

if [[ $active_services -eq 0 ]]; then
    log "Todos os serviços estão inativos. Executando o reboot..."
    # Executa o script de reboot
    if [[ -f "$REBOOT_SCRIPT" ]]; then
        bash "$REBOOT_SCRIPT"  # Execute o script de reboot
        log "Script '$REBOOT_SCRIPT' executado com sucesso."
    else
        log "O script de reboot '$REBOOT_SCRIPT' não foi encontrado."
    fi
else
    log "Ainda há serviços ativos."
fi
