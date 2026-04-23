@echo off
setlocal
:: Check for Admin Privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Please run this script as Administrator.
    pause
    exit
)

:menu
cls
echo =======================================================
echo    UNIVERSAL MACHINE GUID TOOL (Win 2003 - 2025)
echo =======================================================
echo  1. View Current GUID
echo  2. Generate ^& Set New Random GUID
echo  3. Delete GUID (Empty Value)
echo  4. LOCK GUID (Prevent Auto-Regeneration)
echo  5. UNLOCK GUID (Restore Permissions)
echo  6. Exit
echo =======================================================
set /p choice="Select an option (1-6): "

if "%choice%"=="1" goto view
if "%choice%"=="2" goto generate
if "%choice%"=="3" goto delete
if "%choice%"=="4" goto lock
if "%choice%"=="5" goto unlock
if "%choice%"=="6" exit
goto menu

:view
cls
echo [Reading Registry...]
reg query "HKLM\SOFTWARE\Microsoft\Cryptography" /v MachineGuid
pause
goto menu

:generate
cls
echo [Generating GUID...]
:: Compatible with modern PS and legacy systems with PS installed
for /f %%i in ('powershell -command "[guid]::NewGuid().ToString()"') do set NEWGUID=%%i
reg add "HKLM\SOFTWARE\Microsoft\Cryptography" /v MachineGuid /t REG_SZ /d %NEWGUID% /f
echo New GUID set to: %NEWGUID%
pause
goto menu

:delete
cls
echo [Clearing GUID...]
:: We set it to empty rather than deleting the key to prevent immediate repair
reg add "HKLM\SOFTWARE\Microsoft\Cryptography" /v MachineGuid /t REG_SZ /d "" /f
echo GUID has been cleared (set to empty string).
pause
goto menu

:lock
cls
echo [Locking Registry Key...]
:: This uses a Deny ACL for the SYSTEM account on the SetValue permission
:: Works on Win 7, 8, 10, 11, and Servers 2008-2025
powershell -Command "$path = 'HKLM:\SOFTWARE\Microsoft\Cryptography'; $acl = Get-Acl $path; $rule = New-Object System.Security.AccessControl.RegistryAccessRule('SYSTEM', 'SetValue', 'Deny'); $acl.SetAccessRule($rule); Set-Acl $path $acl"
if %errorlevel% neq 0 (
    echo.
    echo PowerShell Lock failed. Attempting legacy CACLS method...
    echo y|cacls "C:\Windows\System32\config" /d SYSTEM >nul 2>&1
)
echo Key locked. Check if MachineGuid can be modified manually to verify.
pause
goto menu

:unlock
cls
echo [Restoring Permissions...]
powershell -Command "$path = 'HKLM:\SOFTWARE\Microsoft\Cryptography'; $acl = Get-Acl $path; $rules = $acl.GetAccessRules($true, $true, [System.Security.Principal.NTAccount]); foreach($rule in $rules) { if($rule.AccessControlType -eq 'Deny') { $acl.RemoveAccessRule($rule) } }; Set-Acl $path $acl"
echo Permissions restored.
pause
goto menu