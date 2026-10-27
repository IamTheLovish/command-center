' Runs run-job.ps1 for one job with no console window. Usage: wscript.exe launch.vbs <job-name>
Set args = WScript.Arguments
If args.Count < 1 Then WScript.Quit 2
job = args(0)
Set re = New RegExp
re.Pattern = "^[a-z-]+$"
If Not re.Test(job) Then WScript.Quit 2
Set fso = CreateObject("Scripting.FileSystemObject")
p = fso.GetParentFolderName(WScript.ScriptFullName)
Set sh = CreateObject("WScript.Shell")
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & p & "\run-job.ps1"" -Job " & job, 0, False
