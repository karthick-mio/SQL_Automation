[CmdletBinding()]
#Default parameters for QAS-ZZA Setup
param (
    [string]$useEnvVar="N",
    #[string]$dbIndex="0001",
    [string]$server="sql-alg-q-weu-hrxpay-01.database.windows.net",
    [string]$payDb="sqldb-alg-q-weu-hrxpay-payroll-",
    [string]$commonDb="sqldb-alg-q-weu-hrxpay-common-01",
    [string]$shardDb="sqldb-alg-q-weu-hrxpay-shardmanager-01",
    [string]$user="mssqladmin",
    [string]$pass="",
    [string]$resourceGroup="rg-alg-t-weu-hrxpay-01",
    [string]$env="QAS",
    [string]$UserAD="products.jenkins@ngahr.com",
    [string]$UserPWDAD="",
    [string]$keyVaultMasterKeyUrl ="https://kv-alg-q-weu-hrxcalc-01.vault.azure.net/keys/pay-always-encrypted-master-key/",
    [string]$clientID="425e8a40-c6d9-4e38-83ac-1f526a527c77",
    [string]$clientSecretenc='',
    [string]$identityUrl="https://hrxidentity-qas.cloudapp.ngahr.com",
    [string]$identityTokenUrl="", #"https://hrxidentity-qas.cloudapp.ngahr.com/connect/token",
    [string]$payApiUrl="https://pay-api-qas-internal.eu.hrx.alight.com/api/external/customers",
    [string]$gcc="ZZA",
    [string]$RunPaySteps="",
    #[string]$RunStepTerraForm="",
    [string]$RunStepPsCreateEncryption="",
    [string]$RunStepPsSetupEncryption="",
    [string]$RunStepSQLPayrollPermissions="",
    [string]$RunStepApiCall="",
    [string]$RunStepCreateUser4DbRead="",
    [string]$ApplicationId = "7fd02135-7e40-4e1d-958e-5a2b0a884205",
    [string]$ApplicationSecret = "",
    [string]$tenantId = "a68231cf-ba7c-48b4-8c57-3373f61f4395",
    [string]$AzureLog = "X",
    [string]$ContinueOnError = "X"
)

$GlobalErrorFlag=0

. "../99-pws_functions.ps1"
WorkAround-clientSecret
Gcc-Case $gcc

if ([string]::IsNullOrEmpty($identityTokenUrl)){
    $identityTokenUrl = $identityUrl + "/connect/token"
}

if ( $useEnvVar -eq "Y" ){
    #$dbIndex=$env:DB_INDEX
    $server=$env:PAY_DB_SERVER
    $payDb=$env:PAY_DB_PAYDB_PREFIX
    $commonDb=$env:PAY_DB_COMMONDB
    $shardDb=$env:PAY_DB_SHARDDB
    $user=$env:PAY_DB_USER
    $pass=$env:PAY_DB_PASS
    $env=$env:ENV
    $UserAD=$env:USERAD
    $UserPWDAD=$env:USERPWDAD
    $keyVaultMasterKeyUrl=$env:PAY_KEYVAULTMASTERKEYURL
    $clientID=$env:PAY_AUTH_SETUP_CLIENTID
    $clientSecret=$env:PAY_AUTH_SETUP_CLIENTSECRET
    $identityTokenUrl=$env:PAY_AUTH_TOKENURL
    $payApiUrl=$env:PAY_CUSTOMER_APIURL
    $gcc=$env:GCC
    $RunPaySteps=$env:RUNPAYSTEPS
    #$RunStepTerraForm=$env:PAY_RUNSTEPTERRAFORM
    $RunStepPsCreateEncryption=$env:PAY_RUNSTEPPSCREATEENCRYPTION
    $RunStepPsSetupEncryption=$env:PAY_RUNSTEPPSSETUPENCRYPTION
    $RunStepSQLPayrollPermissions=$env:PAY_RUNSTEPSQLPAYROLLPERMISSIONS
    $RunStepApiCall=$env:PAY_RUNSTEPAPICALL
}

if ([string]::IsNullOrEmpty($RunPaySteps)){
    Write-Host "All paySteps are skipped, RunPaySteps is empty" -ForegroundColor Blue
    #$RunStepTerraForm=""
    $RunStepPsCreateEncryption=""
    $RunStepPsSetupEncryption=""
    $RunStepSQLPayrollPermissions=""
    $RunStepApiCall=""
}

if ( $RunPaySteps -eq "X" ){
    $PsScript_0="../0-CheckForDBIndex.ps1"
    $PsScript_3_0="../3.0-SetupSqlAdAdmin.ps1"
    $psCreateEncryptionScript="1-Pay_CreateEncryptionKey.ps1"
    $psSetupEncryptionScript="2-Pay_SetupEncryptionKey.ps1"
    $permission_script_1="3.1-Payroll_Permissions.sql"
    $permission_script_2="3.2-Payroll_Permissions.sql"
    $permission_script_3="3.3-Payroll_Permissions.sql"
    $psRunApiCall="4-Pay_apicall.ps1"

<#     if ([string]::IsNullOrEmpty($dbIndex)){
        Display-Log $AzureLog "debug" "dbindex has not been provided, retrieving from db"
        $cmdPS_0 = "./$PsScript_0 -server $server -sqldbPrefix $payDb -username $user -password $pass -$COMPONENT pay"

        Display-Log $AzureLog "command" "Run command: $cmdPS_0"
        try {
            Invoke-Expression $cmdPS_0
            $dbIndex = $env:PAY_NEW_DB
        } catch {
            Write-Host $_
            Display-Log $AzureLog "error" "There was an error with $PsScript_0"
            Continue-Error $ContinueOnError 1 $AzureLog $GlobalErrorFlag
        }
    } else {
        Display-Log $AzureLog "debug" "dbindex($dbIndex) has been provided"
    } #>

    #Setup variables based on Pipeline Parameters
    $payDb = $payDb + $gcc
    $dboptionAD=";Authentication=Active Directory Password; UID=$UserAD; PWD=$UserPWDAD"
    $sqlConString="Server=$server;User=$user;Password=$pass"
    $sqlConStringPayroll=$sqlConString + ";Database=$payDb"
    $sqlConStringShard=$sqlConString + ";Database=$shardDb"
    $sqlConStringCommon=$sqlConString + ";Database=$commonDb"
    $sqlConStringPayrollAD="Server=$server"+$dboptionAD+ ";Database=$payDb"
    
    if ( $env.ToLower() -eq "tstnf" -Or $env.ToLower() -eq "tstm" -Or $env.ToLower() -eq "tstp" ){
        $userEnv = 'TST'
    } else {
        $userEnv = $env
    }
    $variables = "user=hrX-Pay-API-$userEnv"

    $keyVaultMasterKeyUrl = $keyVaultMasterKeyUrl

    if ( $RunStepPsCreateEncryption -eq "X" ){
        Display-Log $AzureLog "debug" "Create encryption Key"
        $cmd_CreateEncryptionScript = "./$psCreateEncryptionScript -server $server -payrollDatabaseName $payDb -username $user -password $pass -keyVaultMasterKeyUrl $keyVaultMasterKeyUrl -ApplicationId $ApplicationId -ApplicationSecret $ApplicationSecret -tenantId $tenantId"
        Display-Log $AzureLog "command" "Run command: $cmd_CreateEncryptionScript"
        try {
            Invoke-Expression $cmd_CreateEncryptionScript
        } catch {
            Write-Host $_
            Display-Log $AzureLog "error" "There was an error with $psCreateEncryptionScript"
            Continue-Error $ContinueOnError 2 $AzureLog $GlobalErrorFlag $GlobalErrorFlag
        }
    }

    if ( $RunStepPsSetupEncryption -eq "X" ){
        Display-Log $AzureLog "debug" "Setup encryption Key"
        $cmd_SetupEncryptionScript = "./$psSetupEncryptionScript -server $server -payDb $payDb -username $user -password $pass -env $env"
        Display-Log $AzureLog "command" "Run command: $cmd_SetupEncryptionScript"
        try {
            Invoke-Expression $cmd_SetupEncryptionScript
        } catch {
            Write-Host $_
            Display-Log $AzureLog "error" "There was an error with $psSetupEncryptionScript"
            Continue-Error $ContinueOnError 3 $AzureLog $GlobalErrorFlag
        }
    }

    if ( $RunStepSQLPayrollPermissions -eq "X" ){
        Display-Log $AzureLog "debug" "Run permission script $permission_script_1"
        try {
            Invoke-Sqlcmd -InputFile $permission_script_1 -ConnectionString $sqlConStringPayrollAD -verbose #-ErrorLevel 20
            if (! $?) { Continue-Error $ContinueOnError 6 $AzureLog $GlobalErrorFlag }
            else { Display-Log $AzureLog "section" "script $permission_script_1 runs without error" }
        } catch {
            Write-Host $_
            Display-Log $AzureLog "error" "There was an error with $permission_script_1"
            Continue-Error $ContinueOnError 4 $AzureLog
        }
        Display-Log $AzureLog "debug" "Run permission script $permission_script_2"
        try {
            Invoke-Sqlcmd -InputFile $permission_script_2 -ConnectionString $sqlConStringPayrollAD -Variable @($variables) -verbose #-ErrorLevel 15
            if (! $?) { Continue-Error $ContinueOnError 8 $AzureLog $GlobalErrorFlag }
            else { Display-Log $AzureLog "section" "script $permission_script_2 runs without error" }
        } catch {
            Write-Host $_
            Display-Log $AzureLog "error" "There was an error with $permission_script_2"
            Continue-Error $ContinueOnError 5 $AzureLog $GlobalErrorFlag
        }
        Display-Log $AzureLog "debug" "Run permission script $permission_script_3"
        try {
            Invoke-Sqlcmd -InputFile $permission_script_3 -ConnectionString $sqlConStringPayrollAD -Variable @($variables) -verbose #-ErrorLevel 15
            if (! $?) { Continue-Error $ContinueOnError 6 $AzureLog $GlobalErrorFlag }
            else { Display-Log $AzureLog "section" "script $permission_script_3 runs without error" }
        } catch {
            Write-Host $_
            Display-Log $AzureLog "error" "There was an error with $permission_script_3"
            Continue-Error $ContinueOnError 6 $AzureLog $GlobalErrorFlag
        }
    }

    if ( $RunStepCreateUser4DbRead -eq "X" ){
        $scriptPath = $MyInvocation.MyCommand.Path
        $scriptFolder = Split-Path $scriptPath -Parent
        $scriptFolder = Split-Path $scriptFolder -Parent
        $SqlScript_12="$scriptFolder/88-CreateUser4DbRead.sql"
        try {
            Invoke-Sqlcmd -InputFile $SqlScript_12 -ConnectionString $sqlConStringPayroll  -verbose #-ErrorLevel 20
            if (! $?) { Continue-Error $ContinueOnError 12 $AzureLog $GlobalErrorFlag }
            else { Display-Log $AzureLog "section" "script $SqlScript_12 runs without error" }
        } catch {
            Write-Host $_
            Display-Log $AzureLog "command" "Run command: Invoke-Sqlcmd -InputFile $SqlScript_12 -ConnectionString $sqlConStringPayroll"
            Display-Log $AzureLog "error" "There was an error with $SqlScript_12"
            Continue-Error $ContinueOnError 12 $AzureLog $GlobalErrorFlag
        } 
    }
    
    if ( $RunStepApiCall -eq "X" ){
        Display-Log $AzureLog "debug" "CallApi to link GCC to index"
        $cmd_psRunApiCall = "./$psRunApiCall -clientID '$clientID' -clientSecretenc '$clientSecretenc' -identityTokenUrl '$identityTokenUrl' -gcc '$GccUpperCase' -payApiUrl '$payApiUrl'"
        Display-Log $AzureLog "command" "Run command: $cmd_psRunApiCall"
        try {
            Invoke-Expression $cmd_psRunApiCall
            Display-Log $AzureLog "section" "script $psRunApiCall runs without error"
        } catch {
            Write-Host $_
            Display-Log $AzureLog "error" "There was an error with $psRunApiCall"
            Continue-Error $ContinueOnError 7 $AzureLog $GlobalErrorFlag
        }
    }
} else {
    Display-Log $AzureLog "debug" "You didn't choose to run the Pay tasks"
}

if ( $ContinueOnError -eq 'X' ){
    Display-Log $AzureLog "debug" "GlobalErrorFlag=$GlobalErrorFlag"
    exit $GlobalErrorFlag
}
