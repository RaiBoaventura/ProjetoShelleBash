# Nome do usuário que deseja manter logado
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\\')[-1]

# Obtém a ID da sessão do usuário atual
$currentSessionId = (quser | Where-Object { $_ -match $currentUser } | ForEach-Object {
    $parts = $_ -split '\s+'
    $parts[2]
}).Trim()

# Obtém todas as sessões ativas no sistema
$sessions = query user | ForEach-Object {
    $parts = $_ -split '\s+'
    [PSCustomObject]@{
        UserName   = $parts[1]
        SessionID  = $parts[2]
    }
}

# Itera por cada sessão para verificar e realizar logoff
foreach ($session in $sessions) {
    $userName = $session.UserName
    $sessionId = $session.SessionID

    # Verifica se o usuário não é o usuário atual e faz logoff
    if ($sessionId -ne $currentSessionId -and $userName -ne $currentUser) {
        Write-Host "Fazendo logoff do usuário: $userName (ID: $sessionId)"
        logoff $sessionId
    }
}

# Cria um arquivo de flag para indicar que o logoff foi concluído
$flagPath = "C:\\Path\\Para\\Flags\\logoff_completed.flag"
New-Item -Path $flagPath -ItemType File -Force

Write-Host "Todos os usuários foram desconectados, exceto: $currentUser. Flag criada em: $flagPath."
