# CI locale : formatage, analyse statique et tests.
# Usage : powershell -ExecutionPolicy Bypass -File tool\ci.ps1

function Invoke-Step([string] $Name, [scriptblock] $Command) {
    Write-Host "==> $Name"
    & $Command
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ECHEC : $Name"
        exit $LASTEXITCODE
    }
}

Invoke-Step 'Formatage' { dart format --output=none --set-exit-if-changed lib test }
Invoke-Step 'Analyse' { flutter analyze }
Invoke-Step 'Tests' { flutter test }

Write-Host 'CI locale : tout est au vert.'
