$errors = $null
$tokens = $null
$path = Join-Path $PSScriptRoot 'ConnectRamCore.ps1'
[void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
if ($errors -and $errors.Count) {
    $errors | ForEach-Object { $_.ToString() }
    exit 1
}
Write-Output 'PARSE_OK'
