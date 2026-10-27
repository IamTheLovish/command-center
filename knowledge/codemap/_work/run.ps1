$env:CC_ACCT='B'
$w='D:\Command Center\knowledge\codemap\_work'
$ins = Get-Content "$w\instructions.txt" | Out-String
foreach ($a in $args) {
  $in = "$w\$a.in.txt"
  ($ins + "`r`n===== DOSSIER =====`r`n" + (Get-Content "$w\$a.dossier.txt" | Out-String)) | Set-Content $in -Encoding UTF8
  powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Command Center\api\offload.ps1" -Model haiku -Task "codemap-$a" -Prompt "Follow the INSTRUCTIONS at the top of the attached file using its DOSSIER." -Files $in -MaxTokens 3000 -Out "$w\$a.haiku.md"
}
