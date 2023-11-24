[CmdletBinding()]
param (
    [string]$p_env="TSTm",
    [string]$clientID="4507817b-d23c-471f-b533-04a8e3c67a52",
    [string]$clientSecretenc='',
    [string]$identityUrl="https://identity-tstm.eu.hrx.alight.com",
    [string]$payApiUrl="https://pay-api-tstm-internal.eu.hrx.alight.com/api/customers",
    [string]$gcc="ZZA",
    [string]$lcc="TO001",
    [string]$payperidID="5303",
    [string]$p_userName='',
    [string]$p_userPass='',
    [boolean]$p_local=$true,
    [boolean]$p_verbose=$true
)
# Load the shared lib
$scriptPath = $MyInvocation.MyCommand.Path
$scriptFolder2 = Split-Path $scriptPath -Parent
$scriptFolder1 = Split-Path $scriptFolder2 -Parent
$scriptFolder = Split-Path $scriptFolder1 -Parent
. "$scriptFolder\99-functionLib"

if ( $p_local -eq $true ){
. "$scriptFolder2\00-credentials.ps1"
}

Decode-clientSecret

$lv_variableUrl = "/$gcc/companyGroups/$lcc/payperiods/$payperidID/recalculate"
$payApiUrl = $payApiUrl + $lv_variableUrl
if ( $p_verbose -eq $true ){
    $payApiUrl
}

$clientSecret = UrlencodeSecret $clientSecretenc
$token = GetIdentityTokenUser $clientID $clientSecret $identityUrl $p_userName $p_userPass

if (! [string]::IsNullOrEmpty($token)){
    $getResponseIdentity = $true
    if ( $p_verbose -eq $true ){
        $token
    }
}

if ( $getResponseIdentity ){
    $PayApiPayload= @{
        globalCustomerCode=$gcc
        localCompanyGroupCode=$lcc
        payPeriodId=$payperidID
    }

    $PayApiJsonBody = $PayApiPayload | ConvertTo-Json
    if ( $p_verbose -eq $true ){
        $PayApiJsonBody
    }

    $PayApiheaders = @{Authorization = "Bearer $token"}
    $PayApiheaders.Add("Content-Type", "application/x-www-form-urlencoded")

    $PayApiParams = @{
        Method = "Post"
        Uri = $payApiUrl
        Body = $PayApiJsonBody
        ContentType = "application/json"
        headers = $PayApiheaders
    }
    if ( $p_verbose -eq $true ){
        $PayApiParams
    }

    try {
        $responsePayApi = Invoke-RestMethod @PayApiParams
        if ( $p_verbose -eq $true ){
            $responsePayApi | ConvertTo-Json
        }
    } catch {
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    }
}
