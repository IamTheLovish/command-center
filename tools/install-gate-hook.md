# Installing the gate hook (for lovish to approve - nothing here is installed yet)

What it does once installed (a Claude Code PreToolUse hook):
- Before every `Task`/`Agent` call it runs `cc.ps1 gate start -NoLog` on the brief (task text, PR number, workflow edits, xhigh = heavy, "open a PR" = new PR, file paths it can see). On any FAIL the call is blocked (exit 2) and the FAIL lines go back to Claude.
- Before every `Bash` call it blocks `pkill`, `killall`, `taskkill /IM`, `Stop-Process -Name` (the "never stop processes by image name" rule).

Files (already on disk, inert until wired): `D:\Command Center\tools\gate-hook.ps1` (the hook), `cc.ps1`, `gate-lib.ps1`.

## Snippet to merge into `%USERPROFILE%\.claude\settings.json` (or the project's `.claude\settings.json`)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Task|Agent",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"D:\\Command Center\\tools\\gate-hook.ps1\"",
            "timeout": 30
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"D:\\Command Center\\tools\\gate-hook.ps1\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

If the file already has a `"hooks"` key, add the two objects to its `"PreToolUse"` array instead of replacing it.

## Notes
- The Bash entry starts PowerShell on every Bash call (about 0.3-0.5 s each). If that is too slow, delete the Bash entry; the Task/Agent entry still works.
- The hook cannot see which files a brief will edit unless the brief names them as paths with a `/`; the commander should still run `cc.ps1 gate start -Files ...` by hand for exact overlap checks.
- Matcher name: older Claude Code calls the sub-agent tool `Task`, newer `Agent`; the matcher lists both.
- To test without installing: `echo {"tool_name":"Bash","tool_input":{"command":"pkill -f java"}} | powershell -NoProfile -File "D:\Command Center\tools\gate-hook.ps1"` must print BLOCKED and exit 2.
- To remove: delete the two objects from settings.json.
