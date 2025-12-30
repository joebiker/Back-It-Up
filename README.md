# Back-It-Up
Quick backup script for windows users.


## Running
Modify the backup-config.ps1 file to meet your back up needs.


### PowerShell Execution Policy

This script requires PowerShell to allow local scripts to run.
If you see an error about script execution being disabled, you may need to update your execution policy.

You can do this by opening PowerShell as Administrator and running:

```
Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser
```

When prompted type 'A' which selected Yes to All.

This change allows scripts you create locally to run while still protecting you from unsigned scripts downloaded from the internet.

When complete, you can return your comfortable policy level:

```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope CurrentUser
```
