# relay.ps1 - file mailbox between Itachi sessions on different Claude accounts (lovish, Oct 27 night:
# "make a tool to automatically bounce information between each other"). ASCII only, PowerShell 5.1.
# Mailboxes: D:\Command Center\relay\<name>\ (one .md per message, oldest first). A message is read once: `read`
# moves it to <name>\done\. The coordinator watches its box with a Monitor; the claude.ai chat is told by a short
# line typed into its reply box (it reads the file with its own commands).
#   relay.ps1 send -To itachi1 -From coordinator -Text "..."   (or -File path)
#   relay.ps1 list -Box coordinator                            (unread, oldest first)
#   relay.ps1 read -Box coordinator                            (prints and archives every unread message)
param(
  [Parameter(Position = 0, Mandatory = $true)][ValidateSet('send', 'list', 'read')][string]$Cmd,
  [string]$To, [string]$From, [string]$Text, [string]$File, [string]$Box
)
$ErrorActionPreference = 'Stop'
$root = Join-Path (Split-Path $PSScriptRoot -Parent) 'relay'
function Box-Dir([string]$n) {
  if ($n -notmatch '^[a-z0-9-]+$') { throw "mailbox name must be lowercase letters, digits or '-': $n" }
  $d = Join-Path $root $n
  New-Item -ItemType Directory -Force (Join-Path $d 'done') | Out-Null
  return $d
}
switch ($Cmd) {
  'send' {
    if (-not $To -or -not $From) { throw 'send needs -To and -From' }
    $body = if ($File) { Get-Content -LiteralPath $File -Raw -Encoding UTF8 } elseif ($Text) { $Text } else { throw 'send needs -Text or -File' }
    $d = Box-Dir $To
    $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss-fff')
    $p = Join-Path $d ("$stamp-from-$From.md")
    $head = "From: $From`r`nTo: $To`r`nSent: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'))Z`r`n`r`n"
    [IO.File]::WriteAllText($p, $head + $body, (New-Object Text.UTF8Encoding($false)))
    Write-Output $p
  }
  'list' {
    if (-not $Box) { throw 'list needs -Box' }
    Get-ChildItem -LiteralPath (Box-Dir $Box) -Filter *.md -File | Sort-Object Name | ForEach-Object { $_.FullName }
  }
  'read' {
    if (-not $Box) { throw 'read needs -Box' }
    $d = Box-Dir $Box
    foreach ($f in @(Get-ChildItem -LiteralPath $d -Filter *.md -File | Sort-Object Name)) {
      Write-Output ('===== ' + $f.Name)
      Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
      Move-Item -LiteralPath $f.FullName -Destination (Join-Path $d 'done') -Force
    }
  }
}
