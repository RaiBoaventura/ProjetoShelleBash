$LOG_FILE = "C:\\Path\\Para\\Logs\\windows_update.log"
$FLAG_FILE = "C:\\Path\\Para\\Flags\\update_completed.flag"

# Função para escrever no log
function Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -Append -FilePath $LOG_FILE
}

# Função para verificar e instalar atualizações usando PSWindowsUpdate
function Update-Windows {
    try {
        Log "Iniciando verificação de atualizações..."
        
        # Obter as atualizações disponíveis, ignorando uma atualização problemática específica
        $updates = Get-WindowsUpdate -AcceptAll -IgnoreReboot | Where-Object {
            $_.Title -notmatch "Brother - Printer - 2/27/2014 12:00:00 AM - 1.4.0.0"
        }

        if ($updates) {
            Log "Encontradas $(($updates | Measure-Object).Count) atualizações relevantes. Iniciando o download e instalação..."

            # Instalar as atualizações filtradas e registrar cada uma no log
            $updates | ForEach-Object {
                Log "Instalando atualização: $($_.Title)"
                Install-WindowsUpdate -KBArticleID $_.KBArticleID -AcceptAll -IgnoreReboot -Verbose
                Log "Atualização $($_.Title) instalada com sucesso."
            }

            Log "Todas as atualizações relevantes foram instaladas com sucesso."

            # Criar arquivo de flag indicando conclusão
            New-Item -Path $FLAG_FILE -ItemType File -Force
            Log "Flag de conclusão criada em: $FLAG_FILE"
        } else {
            Log "Nenhuma atualização relevante encontrada."
            # Criar arquivo de flag indicando conclusão
            New-Item -Path $FLAG_FILE -ItemType File -Force
            Log "Flag de conclusão criada em: $FLAG_FILE"
        }
    } catch {
        Log "Erro ao tentar atualizar o Windows: $_"
    }
}

# Executa a função de atualização
Update-Windows
