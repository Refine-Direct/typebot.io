param(
    [string]$TaskName = "Typebot - Cleanup expired data",
    [string]$BunPath = "bun.exe",
    [PSCredential]$Credential
)

$ErrorActionPreference = "Stop"
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$runnerPath = Join-Path $PSScriptRoot "run.ps1"
$resolvedBunPath = (Get-Command $BunPath -CommandType Application -ErrorAction Stop).Source
if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot ".env"))) {
    throw "The repository root .env file does not exist."
}
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    throw "An activity named '$TaskName' already exists. Inspect it before replacing it."
}

$action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$runnerPath`" -BunPath `"$resolvedBunPath`"" -WorkingDirectory $repositoryRoot
$trigger = New-ScheduledTaskTrigger -Daily -At "05:30"
# An explicit UTC boundary keeps execution at 05:30 UTC through DST changes.
$trigger.StartBoundary = [DateTime]::UtcNow.Date.AddDays(1).AddHours(5).AddMinutes(30).ToString("yyyy-MM-ddTHH:mm:ss'Z'")
$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 12) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

if ($Credential) {
    $null = Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -User $Credential.UserName -Password ($Credential.GetNetworkCredential().Password) -Description "Clean expired Typebot sessions and verification tokens daily at 05:30 UTC." -ErrorAction Stop
} else {
    $principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
    $null = Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Clean expired Typebot data at 05:30 UTC (requires this user to be logged on)." -ErrorAction Stop
}

"Registered '$TaskName' at 05:30 UTC. Automatic execution starts tomorrow; registration does not run cleanup."
