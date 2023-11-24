Function Display-Log{
    #Display-Log $AzureLog "error" "There was an error with $cmd_PS0"
    Param ($IsAzure, $MsgType, $Msg)

    if ( $IsAzure -eq 'X' ){
        Switch ($MsgType)
        {
            error {Write-Output "##vso[task.logissue type=error] $Msg"} 
            command {Write-Output "##[command] $Msg"}
            section {Write-Output "##[section] $Msg"}
            debug {Write-Output "##[debug] $Msg"}
            warning {Write-Output "##[debug] $Msg"}
        }
    } else {
        Switch ($MsgType)
        {
            error {Write-Host "$Msg" -ForegroundColor Red} 
            command {Write-Host "$Msg" -ForegroundColor Blue}
            section {Write-Host "$Msg" -ForegroundColor Green}
            debug {Write-Host "$Msg" -ForegroundColor Green}
            warning {Write-Host "$Msg" -ForegroundColor Yellow}
        }
    }
}
Function Continue-Error{
    #Continue-Error $ContinueOnError 1 $AzureLog
    Param ($ContinueOnError, $ErrorCode, $AzureLog, $ErrorFlag)
    if ( $ContinueOnError -eq 'X' ){
        $ErrorFlag = $ErrorFlag + 1
        $ErrorFlag
        Set-Variable -Name GlobalErrorFlag -Value ($ErrorFlag) -Scope Global
        Display-Log $AzureLog "debug" "there is an error but script will continue (GlobalErrorFlag=$GlobalErrorFlag)"
    } else {
        exit $ErrorCode
    }
}
Function Restrict-GCC{
    Param ($gcc)
    $AllowGCCList = 'ZZZ', 'ZCS', 'ZPM' , 'ZME' , 'ZZB' , 'ZYC', 'ZZP' , 'ZZA' , 'ZPA' , 'Z01' , 'Z05' , 'P01' , 'ZT1' , 'FTB' , 'COO' , 'P02' , 'Z4A'
    if ( $gcc -notin ($AllowGCCList)){
        Display-Log $AzureLog "error" "You can only delete GCC from this list ($AllowGCCList), you tried for $gcc"
        Exit 1
    } else {
        Display-Log $AzureLog "debug" "The GCC ($gcc) can be deleted"
    }
}
Function Create-db{
    Param ($resourceGroupName, $serverName, $databaseName, $performanceLevel)
    # Create a blank database with an S0 performance level
    $database = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
        -ServerName $serverName `
        -DatabaseName $databaseName `
        -RequestedServiceObjectiveName "S0" `
        -SampleName "AdventureWorksLT"
}
Function Create-sqlServer{
    Param ($resourceGroupName, $serverName, $location, $performanceLevel, $adminSqlLogin, $password)
    # Create a server with a system wide unique server name
    $server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
        -ServerName $serverName `
        -Location $location `
        -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
}
Function Create-rg{
    Param ($resourceGroupName, $location)
    # Create a resource group
    $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location
}
Function Encode-clientSecret{
    $EncodeSecret = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($clientSecret))
    Set-Variable -Name clientSecretenc -Value ($EncodeSecret) -Scope Global
}
Function Decode-clientSecret{
    $DecodeSecret = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($clientSecretenc))
    Set-Variable -Name clientSecret -Value ($DecodeSecret) -Scope Global
}
Function WorkAround-clientSecret{
    $clientSecret
    if ( $env.ToLower() -eq "dev" ){
        $clientID = '9c77cc5a-1f98-43e5-9a25-defd2be2c3f2'
        $clientSecret = '4yeb#mWMesXSfmvu6N@4k9jQ18Pgb1ltn80Ibp&eA~BkHw1bup458GN%nHtdQQKw'
    }
    if ( $env.ToLower() -eq "onb" ){
        $clientID = 'd34b25ac-6bd2-4c3f-ad3a-38e6cc4d914a'
        $clientSecret = 'h61*d%t2c#CF3hpRUAgSL%C$mTtjR^9bt#P0ZAZ^tKB67fVE@hDZ3a6mE64DVjkf'
    }
    if ( $env.ToLower() -eq "qas" ){
        $clientID = 'ba43cdd8-8980-49b9-b1b7-4e2dd01ea5f8'
        $clientSecret = 'wteLQRbRxb&ZEqExG*QrCf%VfZTHmYdk$JKf&AwedWNmWEt7SBUVqMVryCF9*NES'
    }
    if ( $env.ToLower() -eq "prd" ){
        $clientID = '723dc851-a2a2-4d68-97d0-28e06564e104'
        $clientSecret = 'RBvCyQb746^%jlM1VJp5G2Xwsr3~MuAdYXnlIgsdRqxlnS&dop4*@Rm8X~jf6cvJ'
    }
    if ( $env.ToLower() -eq "tstnf" ){
        $clientID = 'ab79ff5d-f5db-40a5-a8d2-fa3cf2977937'
        $clientSecret = 'ozNnL$aVkQQO%cseEa*1stozkcbculYACu2c63GtGfzPhSv%ctIHUo3@kndJ#%B*'
    }
    $clientSecret
    Set-Variable -Name clientSecret -Value ($clientSecret) -Scope Global
}
Function Gcc-Case{
    Param ($gcc)
    $GccUpperCase = $gcc.ToUpper()
    $GccLowerCase = $gcc.ToLower()
    Set-Variable -Name GccUpperCase -Value ($GccUpperCase) -Scope Global
    Set-Variable -Name GccLowerCase -Value ($GccLowerCase) -Scope Global
}
Function Lcc-Case{
    Param ($lcc)
    $LccUpperCase = $lcc.ToUpper()
    $LccLowerCase = $lcc.ToLower()
    Set-Variable -Name LccUpperCase -Value ($LccUpperCase) -Scope Global
    Set-Variable -Name LccLowerCase -Value ($LccLowerCase) -Scope Global
}
Function Env-Case{
    Param ($env)
    $EnvUpperCase = $env.ToUpper()
    $EnvLowerCase = $env.ToLower()
    Set-Variable -Name EnvUpperCase -Value ($EnvUpperCase) -Scope Global
    Set-Variable -Name EnvLowerCase -Value ($EnvLowerCase) -Scope Global
}
Function CountryCode-Case{
    Param ($countrycode)
    $countrycodeUpperCase = $countrycode.ToUpper()
    $countrycodeLowerCase = $countrycode.ToLower()
    Set-Variable -Name countrycodeUpperCase -Value ($countrycodeUpperCase) -Scope Global
    Set-Variable -Name countrycodeLowerCase -Value ($countrycodeLowerCase) -Scope Global
}
Function Generate-DefaultLcc{
    Param ($countrycode)
    $countrycodeUpperCase = $countrycode.ToUpper()
    $countrycodeLowerCase = $countrycode.ToLower()
    $defaultLcc = $countrycodeUpperCase+"001"
    return $defaultLcc
}
Function UseEnvVariable{
    Param ($parameter, $envVariable)
    if (! [string]::IsNullOrEmpty($parameter)){
        if (![string]::IsNullOrEmpty($envVariable)){
            $parameter=$envVariable
            Write-Host "$parameter provided as env variable $envVariable"
        }
    }
    return $parameter
}
function SetBooleanValueFromString{
    Param ($parameter)
    if (( $parameter.ToUpper() -eq 'X' ) -or ( $parameter.ToUpper() -eq 'Y' )) {
        $parameter = $True
    } else {
        $parameter = $False
    }
    return $parameter
}
function AddFinalSlash{
    Param ($string, $LastChar)
    # Remove last char mainly used for url ending by /

    $StringLength = $string.length
    $StringLastChar = $string.substring($StringLength-1,1)

    if ( $StringLastChar -eq $LastChar ){
        $UpdatedString  = $string
        Display-Log $AzureLog "debug" "$string already endding by /"
    } else {
        $UpdatedString = $string + '/'
        Display-Log $AzureLog "debug" "Add a final / to $string "
    }
    return $UpdatedString
}
function RemoveFinalChar{
    Param ($string, $LastChar)
    # Remove last char mainly used for url ending by /

    $StringLength = $string.length
    $StringLastChar = $string.substring($StringLength-1,1)

    if ( $StringLastChar -eq $LastChar ){
        $UpdatedString = $string.substring(0,$StringLength-1)
        Display-Log $AzureLog "debug" "Final / removed from $string"
    } else {
        $UpdatedString  = $string
    }
    return $UpdatedString
}
function GetIdentityToken {
    Param ($clientID, $clientSecret, $identityUrl)
    Add-Type -AssemblyName System.Web

    Write-Host "Get Identity Token"
    $identityTokenUrl = $identityUrl + "/connect/token"
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/x-www-form-urlencoded; charset=utf-8")
    #$SecretencodedURL = [System.Web.HttpUtility]::UrlEncode($clientSecret)
    $body ="client_id=$clientID&client_secret=$clientSecret&grant_type=client_credentials"
    $response = Invoke-RestMethod "$identityTokenUrl" -Method 'POST' -Headers $headers -Body $body
    $responseJson = $response  | ConvertTo-Json
    $token = ($responseJson | ConvertFrom-JSON | Select-Object access_token).access_token
    return $token
}
function GetIdentityTokenUser {
    Param ( $p_clientID, 
            $p_clientSecret, 
            $p_identityUrl, 
            $p_userName, 
            $p_userPass, 
            [boolean] $p_verbose=$false, 
            [boolean] $p_scope=$true, 
            [string] $p_scopeValue = 'identity_api.config_read%20identity_api.config_write%20identity_api.user_read%20identity_api.user_write%20offline_access%20openid%20profile%20pay_api.payroll_read%20pay_api.payroll_write%20pay_proxy',
            [string] $p_grantType='client_credentials' )
    
    Add-Type -AssemblyName System.Web

    Write-Host "Get User Identity Token"
    $identityTokenUrl = $p_identityUrl + "/connect/token"
    if ( $p_verbose ){ Write-Host "identityTokenUrl: $identityTokenUrl" }
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/x-www-form-urlencoded; charset=utf-8")
    if ( $p_verbose ){ Write-Host "clientSecret: $clientSecret" }
    if ($p_scope -eq $true){
        $body ="client_id=$p_clientID&client_secret=$p_clientSecret&grant_type=$p_grantType&username=$p_userName&password=$p_userPass&scope=$p_scopeValue"
    } else {
        $body ="client_id=$p_clientID&client_secret=$p_clientSecret&grant_type=$p_grantType&username=$p_userName&password=$p_userPass"
    }
    if ( $p_verbose ){ Write-Host "body: $body" }
    $response = Invoke-RestMethod "$identityTokenUrl" -Method 'POST' -Headers $headers -Body $body
    $responseJson = $response  | ConvertTo-Json
    $token = ($responseJson | ConvertFrom-JSON | Select-Object access_token).access_token
    if ( $p_verbose ){ Write-Host "token: $token" }
    return $token
}
function GetConfigApiGcc {
    Param ($configApiGetGccUrl, $token)

    $CustomerGetheaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $CustomerGetheaders.Add("Content-Type", "application/x-www-form-urlencoded; charset=utf-8")
    $CustomerGetheaders.Add("Authorization","Bearer $token")

    $responseCustomer   = ""
    $RestCustomerStatus = ""
    $RestCustomerError  = ""
    $responseApi = ""

    try {
        $responseCustomer = Invoke-RestMethod $configApiGetGccUrl -Method 'Get' -Headers $CustomerGetheaders -ErrorVariable RestCustomerError
        $responseApi = $responseCustomer | ConvertTo-JSON
    } catch {
        if ($_ -match '404'){
            $RestCustomerStatus = 404
            $RestCustomerError = ""
            Write-Host "Error: $_"
        } else {
            Write-Host "Error: $_"
        }
    }

    $myReturn = @()

    $myReturn += $responseApi
    $myReturn += $RestCustomerStatus
    $myReturn += $RestCustomerError

    return $myReturn 
}
function GetConfigApiLcc {
    Param ($configApiGetLccUrl, $token)

    $LccGetheaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $LccGetheaders.Add("Content-Type", "application/x-www-form-urlencoded; charset=utf-8")
    $LccGetheaders.Add("Authorization","Bearer $token")
    #$RestCmdGetLcc  = "Invoke-RestMethod $configApiGetLccUrl -Method 'Get' -Headers $LccGetheaders"
    $responseLcc    = ""
    $RestLccStatus  = ""
    $RestLccError   = ""
    $responseApi = ""

    #check powershell version
    $lv_ps_version = $PSVersionTable.PSVersion.Major

    if ( $lv_ps_version -ge '7' ) {
        try {
            $responseLcc = Invoke-RestMethod $configApiGetLccUrl -Method 'Get' -Headers $LccGetheaders -SkipHttpErrorCheck -StatusCodeVariable 'RestLccStatus'
            if ( $RestLccStatus -eq '200' ){
                $RestLccError   = ""
            }
            $responseApi = $responseLcc | ConvertTo-JSON
        } catch {
            #Write-Host "Error: $_"
            $RestLccStatus = $_.Exception.Response.StatusCode.value__
            $lv_statusDescription = $_.Exception.Response.StatusDescription
            if ($RestLccStatus -match '404'){
                $RestLccError = ""
            }
            Write-Host "StatusDescription: $lv_statusDescription"
            # if ($_ -match '404'){
            #     $RestLccStatus = 404
            #     $RestLccError = ""
            #     Write-Host "Error: $_"
            # } else {
            #     Write-Host "Error: $_"
            # }
        }
    } else {
        try {
            $responseLcc = Invoke-RestMethod $configApiGetLccUrl -Method 'Get' -Headers $LccGetheaders
            $RestLccStatus = '200'
            $RestLccError  = ""
            $responseApi = $responseLcc | ConvertTo-JSON
        } catch {
            #Write-Host "Error: $_"
            $RestLccStatus = $_.Exception.Response.StatusCode.value__
            $lv_statusDescription = $_.Exception.Response.StatusDescription
            if ($RestLccStatus -match '404'){
                $RestLccError = ""
            }
            Write-Host "StatusDescription: $lv_statusDescription"
            # if ($_ -match '404'){
            #     $RestLccStatus = 404
            #     $RestLccError = ""
            #     Write-Host "Error: $_"
            # } else {
            #     Write-Host "Error: $_"
            # }
        }
    }


    $myReturn = @()
    $myReturn += $responseApi
    $myReturn += $RestLccStatus
    $myReturn += $RestLccError
    return $myReturn
}
function ConfigApiCreateGCC {
    Param ($GccUpperCase, $goid, $token, $configPostGCCUrl, $AzureLog)

    $GccConfigPayload= @{
        code=$GccUpperCase
        name=$GccUpperCase
        goid=$goid
    }

    $GccApiJsonBody = $GccConfigPayload | ConvertTo-Json
    $GccApiJsonBody
    $GccApiheaders = @{Authorization = "Bearer $token"}
    $GccApiheaders.Add("Content-Type", "application/x-www-form-urlencoded")
    #$GccApiheaders
    $GccApiParams = @{
        Method = "Post"
        Uri = $configPostGCCUrl
        Body = $GccApiJsonBody
        ContentType = "application/json"
        headers = $GccApiheaders
    }
    
    try {
        #$GccApiParams
        Invoke-RestMethod @GccApiParams
    } catch {
        if ( $AzureLog -eq 'X' ){
            Write-Output "##[error] $_"
        } else {
            Write-Host "$_" -ForegroundColor Red
        }
        exit 10
    }
}
function ConfigApiUpdateGCC {
    Param ($GccUpperCase, $goid, $token, $configPostGCCUrl, $AzureLog)

    $GccConfigPayload= @{
        name=$GccUpperCase
        goid=$goid
    }

    $GccApiJsonBody = $GccConfigPayload | ConvertTo-Json
    $GccApiJsonBody
    $GccApiheaders = @{Authorization = "Bearer $token"}
    $GccApiheaders.Add("Content-Type", "application/x-www-form-urlencoded")
    #$GccApiheaders
    $lv_url = $configPostGCCUrl + "/" + $GccUpperCase
    $GccApiParams = @{
        Method = "Put"
        Uri = $lv_url 
        Body = $GccApiJsonBody
        ContentType = "application/json"
        headers = $GccApiheaders
    }
    
    try {
        #$GccApiParams
        Invoke-RestMethod @GccApiParams
    } catch {
        if ( $AzureLog -eq 'X' ){
            Write-Output "##[error] $_"
        } else {
            Write-Host "$_" -ForegroundColor Red
        }
        exit 10
    }
}

function ConfigApiCreateLCC {
    Param ($GccUpperCase, $LccUpperCase, $hrisCode, $payrollProviderCode, $token, $configPostLCCUrl, $AzureLog)

    $lccName = $LccUpperCase + " for " + $GccUpperCase

    $LccConfigPayload= @{
        gcc=$GccUpperCase
        lcccode=$LccUpperCase
        hrisCode=$hrisCode
        payrollProviderCode=$payrollProviderCode
        lccName=$lccName
    }

    $LccApiJsonBody = $LccConfigPayload | ConvertTo-Json
    $LccApiJsonBody
    $LccApiheaders = @{Authorization = "Bearer $token"}
    $LccApiheaders.Add("Content-Type", "application/x-www-form-urlencoded")
    #$GccApiheaders
    $LccApiParams = @{
        Method = "Post"
        Uri = $configPostLCCUrl
        Body = $LccApiJsonBody
        ContentType = "application/json"
        headers = $LccApiheaders
    }
    
    try {
        Invoke-RestMethod @LccApiParams
    } catch {
        if ( $AzureLog -eq 'X' ){
            Write-Output "##[error] $_"
        } else {
            Write-Host "$_" -ForegroundColor Red
        }
        exit 20
    }
}
function ConfigApiUpdateLCC {
    Param ($GccUpperCase, $LccUpperCase, $hrisCode, $payrollProviderCode, $token, $configPostLCCUrl, $AzureLog)

    $lccName = $LccUpperCase + " for " + $GccUpperCase

    $LccConfigPayload= @{
        hrisCode=$hrisCode
        payrollProviderCode=$payrollProviderCode
        lccName=$lccName
    }

    $LccApiJsonBody = $LccConfigPayload | ConvertTo-Json
    $LccApiJsonBody
    $LccApiheaders = @{Authorization = "Bearer $token"}
    $LccApiheaders.Add("Content-Type", "application/x-www-form-urlencoded")
    #$GccApiheaders
    $lv_url = $configPostLCCUrl + '/' + $GccUpperCase + '/' + $LccUpperCase
    $LccApiParams = @{
        Method = "Put"
        Uri = $lv_url
        Body = $LccApiJsonBody
        ContentType = "application/json"
        headers = $LccApiheaders
    }
    
    try {
        Invoke-RestMethod @LccApiParams
    } catch {
        if ( $AzureLog -eq 'X' ){
            Write-Output "##[error] $_"
        } else {
            Write-Host "$_" -ForegroundColor Red
        }
        exit 20
    }
}

function ShowMessage {
    Param ($message, $AzureLog)

    if ( $AzureLog -eq 'X' ){
        Write-Output "##[warning] $message"
    } else {
        Write-Host "$message" -ForegroundColor Yellow
    }
}
Function UrlencodeSecret {
    Param ([string] $clientSecretb64, [boolean] $urlEncode = $true, [boolean] $p_verbose = $true)
    $clientSecretdec = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($clientSecretb64)) 
    Add-Type -AssemblyName System.Web
    if ( $urlEncode -eq $true ){
        $clientSecretUrlEnc = [System.Web.HttpUtility]::UrlEncode($clientSecretdec)
        if ( $p_verbose ){ Write-Host "clientSecretdec: $clientSecretdec"; Write-Host "clientSecretUrlEnc: $clientSecretUrlEnc"; }
    } else {
        $clientSecretUrlEnc = $clientSecretdec
    }
    return $clientSecretUrlEnc
}
Function getVersion {
    #Similar function available in \BundlePipeline\99-functionLib.ps1 GetPingUrl()
    Param ($pingUrl)
    #{"Application":"Pay Api","Message":"Server is running...","Started":"2022-03-26T10:12:16.8737998Z","Uptime":507252.5036317,"Version":"22.2.0"}
    $curlOutPut=Invoke-WebRequest -Uri $pingUrl -UseBasicParsing | Select-Object -ExpandProperty Content 
    #"Version":"22.3.0"}
    $version=$curlOutPut.split(',')[4].split(':')[1] 
    #"22.3.0"}  
    $version=$version.Substring(0,$version.Length-1)
    #"22.3.0"
    $version=$version -replace '"',""
    #22.3.0
    $versionArray=$version.Split(".")
    #22 3 0
    $ReleaseVersion=$versionArray[0]+"."+$versionArray[1]
    #22 + . + 3 = 22.3
    return $ReleaseVersion
}
function AddFormFile {
    param ([string]$Path, [string]$Name)

    if ($Path -ne "")
    {    
        $MultipartFormData = [System.Net.Http.MultipartFormDataContent]::new()
        $FileStream = [System.IO.File]::OpenRead($Path)
        $FileName = [System.IO.Path]::GetFileName($Path)
        $FileContent = [System.Net.Http.StreamContent]::new($FileStream)
        $MultipartFormData.Add($FileContent, $Name, $FileName)
    }
}
function CheckPayGroupExist{
    param (
        [string] $p_response,
        [string] $p_paygroupSearch
    )
    #write-Host "p_response: $p_response"
    $j = $p_response | ConvertFrom-Json
    $PayGroupInJson = ($j | Where-Object payGroupCode -eq $p_paygroupSearch).payGroupCode
    #Write-Host "PayGroupInJson : $PayGroupInJson "
    if([string]::IsNullOrEmpty($PayGroupInJson)) {
        $lv_PayGroupFound = $false
        Write-Host "The PayGroup $p_paygroupSearch is not found"
        exit 2
    } else {
        $lv_PayGroupFound = $true
        Write-Host "The PayGroup $p_paygroupSearch is found"
    }
    return $lv_PayGroupFound
}

function UploadCustomerWorkbook{
    param (
        [string] $p_token,
        [string] $p_gcc,
        [string] $p_uri,
        [string] $p_filename,
        [string] $p_filePath
    )

    Write-Host "Trying to upload workbook $p_filename from $p_filePath"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $p_token")

    $lv_url = $p_uri + $p_gcc + "/workbook/parse-configuration"
    #$fileBin = [System.IO.File]::ReadAlltext($p_filePath)
    
    $fileBin = [System.IO.File]::ReadAllBytes($p_filePath)
    $CODEPAGE = "iso-8859-1" # alternatives are ASCII, UTF-8 
    $enc = [System.Text.Encoding]::GetEncoding($CODEPAGE)
    $fileEnc = $enc.GetString($fileBin)

    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    $body = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$p_fileName`"",
        "Content-Type: application/octet-stream$LF",
        $fileEnc,
        "--$boundary--$LF"
    ) -join $LF
    try {
        $response = Invoke-RestMethod -Uri $lv_url -Method POST -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $body -Headers $headers
        $response | ConvertTo-Json
    } catch {
        # Dig into the exception to get the Response details.
        # Note that value__ is not a typo.
        #Write-Host "Response:" $_.Exception.Response
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        exit 1
    }
}

function UpdateCustomerWorkbook{
    param (
        [string] $p_token,
        [string] $p_gcc,
        [string] $p_lcc,
        [string] $p_uri,
        [string] $p_filename,
        [string] $p_documentID
    )

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $p_token")

    $lv_url = $p_uri + '/api/workbooks/customers/' + $p_gcc + "/companyGroups/" + $p_lcc + '/' + $p_documentID
    Write-Host "lv_url: $lv_url"

    $fileBin = [System.IO.File]::ReadAlltext($lv_excelFile)
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    $body = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$p_filename`"",
        "Content-Type: application/octet-stream$LF",
        $fileBin,
        "--$boundary--$LF"
    ) -join $LF
    try {
        $response = Invoke-RestMethod -Uri $lv_url -Method 'Put' -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $body -Headers $headers
        $response | ConvertTo-Json
    } catch {
        # Dig into the exception to get the Response details.
        # Note that value__ is not a typo.
        #Write-Host "Response:" $_.Exception.Response
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    }
}
function generatePassowrd{
    param (
        [int] $p_passwordLength=13
    )
    $validCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!-_+"
    $random = New-Object System.Random
    $password = ''

    while ($password.Length -lt $p_passwordLength) {
        $randomCharacter = $validCharacters[$random.Next(0, $validCharacters.Length)]
        $password += $randomCharacter
    }

    # Validate the generated password against complexity requirements
    #$meetsRequirements = $password -match "^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*()-_=+[\]{}<>,.?/:;]).{8,}$"
    
    #having atleast two special char !-_=+
    $meetsRequirements = $password -match "^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!-_=+].*[!-_=+]).{8,}$"
    #having atleast one special char !-_=+
    #$meetsRequirements = $password -match "^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!-_=+]).{8,}$"


    if (!$meetsRequirements) {
        # If the generated password does not meet the complexity requirements, generate a new one
        $password = generatePassowrd -p_passwordLength $p_passwordLength
    }

    return $password
}

function getCoreKeyVault{
    Param ($landscape, $environmnet)
    switch ($landscape) {
        "EU01" {  
            switch ($environmnet) {
                "TST01" { $keyvault = "kv-alg-t-weu-hrxcore-01" }
                "TSTEU" { $keyvault = "kv-alg-t-weu-hrxcore-01" }
                "TST02" { $keyvault = "kv-alg-t-weu-hrxcore-02" }
                "TSTNF" { $keyvault = "kv-alg-t-weu-hrxcore-02" }
                "TST03" { $keyvault = "kv-alg-t-weu-hrxcore-03" }
                "TSTM" { $keyvault = "kv-alg-t-weu-hrxcore-03" }
                "TST04" { $keyvault = "kv-alg-t-weu-hrxcore-04" }
                "TSTP" { $keyvault = "kv-alg-t-weu-hrxcore-04" }
                "TST05" { $keyvault = "kv-alg-t-weu-hrxcore-05" }
                "DEV" { $keyvault = "kv-alg-t-weu-hrxcore-05" }
                "TST06" { $keyvault = "kv-alg-t-weu-hrxcore-06" }
                "DEVNX" { $keyvault = "kv-alg-t-weu-hrxcore-06" }
                "TST07" { $keyvault = "kv-alg-t-weu-hrxcore-07" }
                "TSTNX" { $keyvault = "kv-alg-t-weu-hrxcore-07" }
                "ONB" { $keyvault = "kv-alg-o-weu-hrxcore-01" }
                "QAS" { $keyvault = "kv-alg-q-weu-hrxcore-01" }
                "PRD" { $keyvault = "kv-alg-p-weu-hrxcore-01" }
                Default { Write-Host "environment is not matching in switch $environmnet under landscape $landscape" }
            }
        }
        "US01" {
            switch ($environmnet) {
                "ONB" { $keyvault = "kv-alg-o-cus-hrxcore-01" }
                "ONBNF" { $keyvault = "kv-alg-o-cus-hrxcore-02" }
                "ONB-NF" { $keyvault = "kv-alg-o-cus-hrxcore-02" }
                "QAS" { $keyvault = "kv-alg-q-cus-hrxcore-01" }
                "PRD" { $keyvault = "kv-alg-p-cus-hrxcore-01" }
                "PRD-DR" { $keyvault = "kv-alg-p-eus2-hrxcore-01" }
                "DR" { $keyvault = "kv-alg-p-eus2-hrxcore-01" }
                Default { Write-Host "environment is not matching in switch $environmnet under landscape $landscape" }
            }
        }
        "US02" {
            switch ($environmnet) {

                Default { Write-Host "environment is not matching in switch $environmnet under landscape $landscape" }
            }            
        }
        "US03" {
            switch ($environmnet) {
                "ONB" { $keyvault = "kv-alg-o-cus-hrxcore-31" }
                "QAS" { $keyvault = "kv-alg-q-cus-hrxcore-31" }
                "PRD" { $keyvault = "kv-alg-p-cus-hrxcore-31" }
                Default { Write-Host "environment is not matching in switch $environmnet under landscape $landscape" }
            }              
        }                
        Default { Write-Host "landscape is not matching in switch $landscape"  }
    }
    return $keyvault
}







# function GetCustomerWorkbook{
#     param (
#         [string] $p_token,
#         [string] $p_gcc,
#         [string] $p_lcc,
#         [string] $p_uri,
#         [string] $p_filename,
#         [string] $p_documentID
#     )

#     $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
#     $headers.Add("Authorization", "Bearer $p_token")

#     $lv_url = $p_uri + '/api/workbooks/customers/' + $p_gcc + "/companyGroups/" + $p_lcc + '/' + $p_documentID
#     Write-Host "lv_url: $lv_url"

#     $fileBin = [System.IO.File]::ReadAlltext($lv_excelFile)
#     $boundary = [System.Guid]::NewGuid().ToString()
#     $LF = "`r`n"
#     $body = (
#         "--$boundary",
#         "Content-Disposition: form-data; name=`"file`"; filename=`"$p_filename`"",
#         "Content-Type: application/octet-stream$LF",
#         $fileBin,
#         "--$boundary--$LF"
#     ) -join $LF
#     try {
#         $response = Invoke-RestMethod -Uri $lv_url -Method 'Put' -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $body -Headers $headers
#         $response | ConvertTo-Json
#     } catch {
#         # Dig into the exception to get the Response details.
#         # Note that value__ is not a typo.
#         #Write-Host "Response:" $_.Exception.Response
#         Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
#         Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
#     }
# }

function GetLandscapeFromAppConfigConn{
    param (
        [string]$p_appConfigConn
    )
    $lv_appConfigName = $p_appConfigConn.split('/')[2]
    $lv_appConfigName = $lv_appConfigName.split(';')[0]
    Write-Host "lv_appConfigName: $lv_appConfigName"
    switch ($lv_appConfigName) {
        'ac-alg-d-weu-hrxcore-01.azconfig.io' { $lv_landscape = 'eu01-lab' }
        'appcg-alg-t-weu-hrx-appcg-01.azconfig.io' { $lv_landscape = 'eu01' }
        'appcg-alg-p-weu-hrx-appcg-01.azconfig.io' { $lv_landscape = 'eu01' }
        'appcg-alg-p-neu-hrx-appcg-01.azconfig.io' { $lv_landscape = 'eu01' }
        'appcg-alg-p-cus-hrx-appcg-01.azconfig.io' { $lv_landscape = 'us01' }
        'appcg-alg-p-eus2-hrx-appcg-01.azconfig.io' { $lv_landscape = 'us01' }
        'appcg-alg-p-cus-hrx-appcg-21.azconfig.io' { $lv_landscape = 'us02' }
        'appcg-alg-p-eus2-hrx-appcg-21.azconfig.io' { $lv_landscape = 'us02' }
        'appcg-alg-p-cus-hrx-appcg-31.azconfig.io' { $lv_landscape = 'us03' }
        'appcg-alg-p-eus2-hrx-appcg-31.azconfig.io' { $lv_landscape = 'us03' }
        Default { $lv_landscape = 'eu01' }
    }
    Write-Host "landscape for this AppConn is $lv_landscape"
    return $lv_landscape
}


function MapEnvToLabel {
    param (
        [string] $p_env,
        [string] $p_appConfigConn
    )
    Write-Host "Mapping environments to AppConfigLabels"
    $lb_mappingNeeded=$true

    if (-not [string]::IsNullOrEmpty($p_env)){
        $lv_label=$p_env
        switch ($p_env) {
            'DEV' { $lb_mappingNeeded=$false }
            'TST05' { $lb_mappingNeeded=$false }
            'TST02' { $lb_mappingNeeded=$false }
            'TST03' { $lb_mappingNeeded=$false }
            'TSTNF' { $lb_mappingNeeded=$false }
            'TSTM' { $lb_mappingNeeded=$false }            
            'TST04' { $lb_mappingNeeded=$false }
            'TST06' { $lb_mappingNeeded=$false }
            'TST07' { $lb_mappingNeeded=$false }
            'ONB-01' { $lb_mappingNeeded=$false }
            'ONB-02' { $lb_mappingNeeded=$false }
            'QAS-01' { $lb_mappingNeeded=$false }
            'QAS-02' { $lb_mappingNeeded=$false }
            'PRD-01' { $lb_mappingNeeded=$false }
            #'EU01-PRD-DR-01' { $lb_mappingNeeded=$false }
            'ONB-21' { $lb_mappingNeeded=$false }
            'QAS-21' { $lb_mappingNeeded=$false }
            'PRD-21' { $lb_mappingNeeded=$false }
            #'PRD-DR-21' { $lb_mappingNeeded=$false }
            'ONB-31' { $lb_mappingNeeded=$false }
            'QAS-31' { $lb_mappingNeeded=$false }
            'PRD-31' { $lb_mappingNeeded=$false }
            #'PRD-DR-31' { $lb_mappingNeeded=$false }
            Default { $lb_mappingNeeded=$true }
        }
    }
    if ( $lb_mappingNeeded -eq $true){
        Write-Host "Mapping Needed for $p_env"
        $lv_landscape = GetLandscapeFromAppConfigConn -p_appConfigConn $p_appConfigConn
        $lv_switcher = $lv_landscape.tolower() + '-' + $p_env.tolower()
        Write-host "lv_switcher: $lv_switcher"
        switch ($lv_switcher.tolower()) {
            'eu01-lab-dev' { $lv_label='dev' }
            'eu01-lab-tstnf' { $lv_label='tstnf' }
            'eu01-lab-tstm' { $lv_label='tstm' }
            'eu01-dev' { $lv_label='TST05' }
            'eu01-devnx' { $lv_label='TST06' }
            'eu01-tstnf' { $lv_label='TST02' }
            'eu01-tstm' { $lv_label='TST03' }
            'eu01-tst02' { $lv_label='TST02' }
            'eu01-tst03' { $lv_label='TST03' }            
            'eu01-tstp' { $lv_label='TST04' }
            'eu01-tstnx' { $lv_label='TST07' }

            'eu01-onb' { $lv_label='ONB-01' }
            'eu01-qas' { $lv_label='QAS-01' }
            'eu01-qas01' { $lv_label='QAS-01' }
            'eu01-prd' { $lv_label='PRD-01' }
            'eu01-prd01' { $lv_label='PRD-01' }

            'us01-onb' { $lv_label='ONB-01' }
            'us01-onbnf' { $lv_label='ONB-02' }
            'us01-qas' { $lv_label='QAS-01' }
            'us01-prd' { $lv_label='PRD-01' }

            'us02-onb' { $lv_label='ONB-21' }
            'us02-qas' { $lv_label='QAS-21' }
            'us02-prd' { $lv_label='PRD-21' }

            'us03-onb' { $lv_label='ONB-31' }
            'us03-qas' { $lv_label='QAS-31' }
            'us03-prd' { $lv_label='PRD-31' }
            Default {}
        }
    }
    return $lv_label
}

function InstallModule {
    param (
        [string] $p_module,
        [string] $p_moduleVersion
    )
    Write-Host "Install & Import Module $p_module"
    if ([string]::IsNullOrEmpty($p_moduleVersion)){ 
        Install-Module -Name $p_module -AllowClobber -Scope CurrentUser -Force
    } else {
        Install-Module -Name $p_module  -MinimumVersion $p_moduleVersion -AllowClobber -Scope CurrentUser -Force 
    }
    
}

function InstallModuleIfNeeded {
    param (
        [string] $p_moduleName,
        [string] $p_moduleVersion
    )
    if (-not (Get-Module -Name $p_moduleName -ListAvailable)) {

        if ([string]::IsNullOrEmpty($p_moduleVersion)){ 
            InstallModule -p_module $p_moduleName
            Import-Module -Name $p_moduleName -ErrorAction SilentlyContinue
        } else {
            InstallModule -p_module $p_moduleName -p_moduleVersion $p_moduleVersion
            Import-Module -Name $p_moduleName -ErrorAction SilentlyContinue -MinimumVersion $p_moduleVersion -MaximumVersion $p_moduleVersion
        }

        #-MinimumVersion 2.0.0
        #import-module 'SqlServer' -MinimumVersion $lv_sqlServerVersion -MaximumVersion $lv_sqlServerVersion
    }
}

function DefineDbConnectionVariables {
    param (
        [string] $p_db_prefix,
        [string] $p_gcc,
        [string] $p_user,
        [string] $p_pass,
        [string] $p_userAD,
        [string] $p_passAD,
        [string] $p_shardDb,
        [string] $p_commonDb,
        [string] $p_server,
        [boolean] $p_verbose
    )
    #Setup variables based on Pipeline Parameters
    $GccDb = $p_db_prefix + $p_gcc.tolower()
    $lv_masterDb = "master"

    $dboptions="Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;"
    $dboptionAD=";Authentication=Active Directory Password; UID=$p_userAD; PWD=$p_passAD"

    $sqlConString="Server=$p_server;User=$p_user;Password=$p_pass"
    $sqlConStringGCC=$sqlConString + ";Database=$GccDb"
    $sqlConStringShard=$sqlConString + ";Database=$p_shardDb"
    
    #$sqlConStringmaster="Server=$server"+$dboptionAD+ ";Database=$masterDb"
    $sqlConStringmaster=$sqlConString + ";Database=$lv_masterDb"
    #$sqlConStringCommon=$sqlConString + ";Database=$p_commonDb"

    if ( $p_verbose -eq $true){
        Write-Host "Show variables in DefineDbConnectionVariables"
        Write-Host "GccDb= $GccDb"
        Write-Host "lv_masterDb= $lv_masterDb"
        Write-Host "dboptions= $dboptions"
        Write-Host "dboptionAD= $dboptionAD"
        Write-Host "sqlConString= $sqlConString"
        Write-Host "sqlConStringGCC= $sqlConStringGCC"
        Write-Host "sqlConStringShard= $sqlConStringShard"
        Write-Host "sqlConStringmaster= $sqlConStringmaster"
    }
    $la_sqlConnStrg = @()
    $la_sqlConnStrg += $GccDb
    $la_sqlConnStrg += $sqlConString
    $la_sqlConnStrg += $sqlConStringGCC
    $la_sqlConnStrg += $sqlConStringShard
    $la_sqlConnStrg += $sqlConStringmaster

    Write-Host "la_sqlConnStrg= $la_sqlConnStrg"

    return $la_sqlConnStrg
}

function DefineSqlScripts4Module {
    param ( 
        [string] $p_module = 'exchange',
        [string] $p_release
        )

    $la_scripts = @()
    switch ($p_module.tolower()) {
        'exchange' { 
            #Create ShareDBObjects
            $SqlScript_1 ="$scriptFolderUp/shardManager/1-ShardManager_CreateObjects.sql"
            $SqlScript_2 = "$scriptFolderUp/shardManager/2-ShardManager-GCC.sql"
            $SqlScript_3 = "$scriptFolderUp/shardManager/3-GCCDB_ObjectCreation.sql"
            $SqlScript_4 = "$scriptFolderUp/shardManager/4-GCCDB_SetupShard.sql"

            $nlopScript ="$scriptFolder/nlop_$p_release.sql"

            $SqlScript_12 = "$scriptFolderUp/88-CreateUser4DbRead.sql"

            $la_scripts += $SqlScript_1
            $la_scripts += $SqlScript_2
            $la_scripts += $SqlScript_3
            $la_scripts += $SqlScript_4
            $la_scripts += $nlopScript
            $la_scripts += $SqlScript_12
        }
        Default { Write-Host "Please define the module in DefineSqlScripts4Module"; exit 1}
    }

    return $la_scripts
}

function SetupPwsAzureModule4Setup {
    #### Install required powershell moduels
    $lv_AzAccountVersion ="2.12.4"
    $lv_sqlserver ="21.1.18256"
    $lv_keyVaultVersion ="4.10.0"
    InstallModuleIfNeeded -p_moduleName 'AzureAD' 
    InstallModuleIfNeeded -p_moduleName 'SqlServer' -p_moduleVersion $lv_sqlserver
    InstallModuleIfNeeded -p_moduleName 'Az.KeyVault' -p_moduleVersion $lv_keyVaultVersion
    InstallModuleIfNeeded -p_moduleName 'Az.Accounts' -p_moduleVersion $lv_AzAccountVersion
    import-module 'Az.Resources' 
    Import-Module -Name AzureAD
    Import-Module -Name SqlServer
}

function Connect2Graph {
    Write-Host "Connect to Microsoft Graph using Azure AD token"
    $lo_context = Get-AzContext;
    Write-Host "lo_context:$lo_context"
    $lo_aadToken = Get-AzAccessToken -ResourceTypeName AadGraph;
    $lo_graphToken = Get-AzAccessToken -Resource "https://graph.microsoft.com/";
    Connect-AzureAD -AadAccessToken $lo_aadToken.Token -AccountId $lo_context.Account.Id -Tenant $tenantID -MsAccessToken $lo_graphToken.Token;
}

function executeSQLscript {
    param (
        [string] $p_scriptName,
        [string] $p_connectionString,
        [array] $p_variables,
        [int] $p_errorID
    )
    Write-Host "----------------------------- $p_scriptName -----------------------------------------"
    if ([string]::IsNullOrEmpty($p_variables)) {
        try {
            $lv_ResultSQL = Invoke-Sqlcmd -InputFile $p_scriptName -ConnectionString $p_connectionString -verbose #-ErrorLevel 20
            if (! $?) { Continue-Error $ContinueOnError 1 $AzureLog $GlobalErrorFlag }
            else { 
                Display-Log $AzureLog "section" "script $p_scriptName runs without error" 
                return $lv_ResultSQL
            }
            
        } catch {
            Write-Host $_
        Display-Log $AzureLog "command" "Run command: Invoke-Sqlcmd -InputFile $p_scriptName -ConnectionString $p_connectionString"
            Display-Log $AzureLog "error" "There was an error with $p_scriptName"
            Continue-Error $ContinueOnError $p_errorID $AzureLog $GlobalErrorFlag
        }
    } else {
        Write-Host "p_variables = $p_variables"
        try {
            $lv_ResultSQL = Invoke-Sqlcmd -InputFile $p_scriptName -ConnectionString $p_connectionString  -Variable @($p_variables)  -verbose #-ErrorLevel 20
            if (! $?) { Continue-Error $ContinueOnError 1 $AzureLog $GlobalErrorFlag }
            else { 
                Display-Log $AzureLog "section" "script $p_scriptName runs without error"
                return $lv_ResultSQL
            }
            
        } catch {
            Write-Host $_
            Display-Log $AzureLog "command" "Run command: Invoke-Sqlcmd -InputFile $p_scriptName -ConnectionString $p_connectionString" -Variable @($p_variables) -verbose 
            Display-Log $AzureLog "error" "There was an error with $p_scriptName"
            Continue-Error $ContinueOnError $p_errorID $AzureLog $GlobalErrorFlag
        }
    }
}
