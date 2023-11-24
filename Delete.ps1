
[CmdletBinding()]
#Default parameters to delete TST-ZZZ
param (
    #[string]$DbIndex="0001", #can be number or gcc
    [string]$server="sql-alg-t-weu-hrxpay-01.database.windows.net",
    [string]$payDb="sqldb-alg-t-weu-hrxpay-payroll-",
    [string]$commonDb="sqldb-alg-t-weu-hrxpay-common-01",
    [string]$shardDb="sqldb-alg-t-weu-hrxpay-shardmanager-01",
    [string]$user="mssqladmin",
    [string]$pass="",
    [string]$env="",
    [string]$gcc="ZZZ",
    [string]$AzureLog = "X",
    [string]$ContinueOnError = "X"
)

$GlobalErrorFlag=0

. "../99-pws_functions.ps1"
Gcc-Case $gcc
Restrict-GCC $GccUpperCase

$PsScript_0="../0-CheckForDBIndex.ps1"
#$SqlScript_1="d01-Common_DelGcc.sql"
# $SqlScript_2="d02-Shardmanager_DelGcc.sql"
$SqlScript_3="d03-payroll_DelGcc.sql"

<# if ([string]::IsNullOrEmpty($dbIndex)){
    Display-Log $AzureLog "debug" "dbindex has not been provided, retrieving from db"
    $cmd_PS0 = "./$PsScript_0 -server $server -sqldbPrefix $payDb -username $user -password $pass -$COMPONENT = pay"
    try {
        Invoke-Expression $cmd_PS0
        $DbIndex = $env:PAY_NEW_DB
        Display-Log $AzureLog "section" "script $PsScript_0 runs without error"
    } catch {
        Display-Log $AzureLog "error" "There was an error with $cmd_PS0"
    }
} else {
    Display-Log $AzureLog "debug" "dbindex($dbIndex) has been provided"
} #>

#Setup variables based on Pipeline Parameters
$payDb = $payDb + $gcc
$dboptions="Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;"
$sqlConStringPay="Server=$server;User=$user;Password=$pass"
$dboptionAD=";Authentication=Active Directory Password; UID=$UserAD; PWD=$UserPWDAD"
$sqlConStringPayPayroll=$sqlConStringPay + ";Database=$payDb"
$sqlConStringPayShard=$sqlConStringPay + ";Database=$shardDb"
$sqlConStringPayCommon=$sqlConStringPay + ";Database=$commonDb"
# $sqlConStringPayPayrollAD="Server=$server"+$dboptionAD+ ";Database=$payDb"
# $sqlConStringPayCommonAD="Server=$server"+$dboptionAD+ ";Database=$commonDb"
# $sqlConStringPayShardAD="Server=$server"+$dboptionAD+ ";Database=$shardDb"
# $keyVaultMasterKeyUrl = $keyVaultMasterKeyUrl

# $variables_1 = "gcc=$GccUpperCase"
# try {
#     Invoke-Sqlcmd -InputFile $SqlScript_1 -ConnectionString $sqlConStringPayCommon -Variable @($variables_1) -verbose #-ErrorLevel 20
#     if (! $?) { Continue-Error $ContinueOnError 1 $AzureLog $GlobalErrorFlag }
#     else { Display-Log $AzureLog "section" "script $SqlScript_1 runs without error" }
    
# } catch {
#     Write-Host $_
#     Display-Log $AzureLog "command" "Run command: Invoke-Sqlcmd -InputFile $SqlScript_1 -ConnectionString $sqlConStringPayCommon -Variable $variables_1"
#     Display-Log $AzureLog "error" "There was an error with $SqlScript_1"
#     Continue-Error $ContinueOnError 1 $AzureLog $GlobalErrorFlag
# }

# $variables_2 = "gcc=$GccUpperCase", "databaseName=$payDb"
# try {
#     Invoke-Sqlcmd -InputFile $SqlScript_2 -ConnectionString $sqlConStringPayShard -Variable @($variables_2)#-ErrorLevel 20
#     if (! $?) { Continue-Error $ContinueOnError 2 $AzureLog $GlobalErrorFlag }
#     else { Display-Log $AzureLog "section" "script $SqlScript_2 runs without error"}
    
# } catch {
#     Write-Host $_
#     Display-Log $AzureLog "command" "Run command: Invoke-Sqlcmd -InputFile $SqlScript_2 -ConnectionString $sqlConStringPayShard" -Variable @($variables_2)
#     Display-Log $AzureLog "error" "There was an error with $SqlScript_2"
#     Continue-Error $ContinueOnError 2 $AzureLog $GlobalErrorFlag
# }

$variables_3 = "gcc=$GccUpperCase"
try {
    Invoke-Sqlcmd -InputFile $SqlScript_3 -ConnectionString $sqlConStringPayPayroll -Variable @($variables_3) -verbose #-ErrorLevel 20
    if (! $?) { Continue-Error $ContinueOnError 1 $AzureLog $GlobalErrorFlag }
    else { Display-Log $AzureLog "section" "script $SqlScript_3 runs without error" }
    
} catch {
    Write-Host $_
    Display-Log $AzureLog "command" "Run command: Invoke-Sqlcmd -InputFile $SqlScript_3 -ConnectionString $sqlConStringPayPayroll -Variable $variables_3"
    Display-Log $AzureLog "error" "There was an error with $SqlScript_3"
    Continue-Error $ContinueOnError 1 $AzureLog $GlobalErrorFlag
}


if ( $ContinueOnError -eq 'X' ){
    Display-Log $AzureLog "debug" "GlobalErrorFlag=$GlobalErrorFlag"
    exit $GlobalErrorFlag
}
