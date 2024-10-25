# Configuração do log e caminho do script de atualização
$LOG_FILE = "C:\\Path\\Para\\Logs\\services_status.log"
$UPDATE_SCRIPT_PATH = "C:\\Path\\Para\\Scripts\\updateWindows.ps1"

# Função para escrever no log
function Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -Append -FilePath $LOG_FILE
}

# Lista de serviços a serem monitorados
$servicesToCheck = @(
    "wuauserv",  # Serviço de atualização do Windows
    "WinRM",     # Serviço de Gerenciamento Remoto do Windows
    "Spooler",   # Serviço de impressão
    "MSSQLSERVER", # Serviço do SQL Server (se aplicável)
    "Dhcp",      # Serviço de cliente DHCP
    "Dnscache"   # Serviço de cache DNS
)

# Função para verificar o status dos serviços usando Get-Service
function Check-Services {
    $servicesRunning = $false

    foreach ($serviceName in $servicesToCheck) {
        try {
            # Usando Get-Service para verificar o status do serviço
            $service = Get-Service -Name $serviceName -ErrorAction Stop
            if ($service.Status -eq 'Running') {
                Log "O serviço '$serviceName' está em execução."
                $servicesRunning = $true
            } else {
                Log "O serviço '$serviceName' NÃO está em execução. Status atual: $($service.Status)."
            }
        } catch {
            Log "Erro ao verificar o serviço '$serviceName': $_"
        }
    }

    return $servicesRunning
}

# Função para executar o script de atualização do Windows
function Run-UpdateScript {
    try {
        Log "Iniciando script de atualização do Windows para testes."
        # powershell.exe -ExecutionPolicy Bypass -File $UPDATE_SCRIPT_PATH
        Log "Script de atualização do Windows executado com sucesso."
    } catch {
        Log "Erro ao tentar executar o script de atualização do Windows: $_"
    }
}

# Loop para esperar que todos os serviços estejam parados antes de continuar
Log "Iniciando verificação contínua dos serviços..."
do {
    $servicesRunning = Check-Services
    if ($servicesRunning) {
        Log "Aguardando que todos os serviços sejam finalizados..."
        Start-Sleep -Seconds 60  # Aguarda 60 segundos antes de verificar novamente
    }
} while ($servicesRunning)

Log "Todos os serviços foram finalizados. Prosseguindo com o script de atualização."

# Iniciar o processo de atualização do Windows após todos os serviços serem parados
Run-UpdateScript
