param(
    [string]$BunPath = "bun.exe",
    [switch]$Check
)

$ErrorActionPreference = "Stop"
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$logDirectory = Join-Path $repositoryRoot "logs\jobs\cleanup-expired-data"
$null = New-Item -ItemType Directory -Force -Path $logDirectory
$logPrefix = Join-Path $logDirectory (Get-Date -Format "yyyyMMdd-HHmmss-fff")
$arguments = @("x", "nx", "run", "cleanup-expired-data:run", "--skip-nx-cache", "--no-cloud")
if ($Check) { $arguments += "--check" }

# Use absolute runtime paths in the scheduled task and avoid a background Nx daemon.
$env:NX_DAEMON = "false"
$env:NX_ISOLATE_PLUGINS = "false"
$env:NX_INTERACTIVE = "false"
try {
    $process = Start-Process -FilePath $BunPath -ArgumentList $arguments -WorkingDirectory $repositoryRoot -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$logPrefix.out.log" -RedirectStandardError "$logPrefix.error.log"
    exit $process.ExitCode
} catch {
    Write-Error "Unable to launch cleanup. Verify Bun, repository permissions and dependencies. Logs: $logDirectory" -ErrorAction Continue
    exit 1
}
