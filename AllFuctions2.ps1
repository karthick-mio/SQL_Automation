

$envArray = @('onb','qas','prd','qa2','onbnf')
$lv_basicAuth = $env:TokenFromKv
function GetRestorePoint {
    if (![string]::IsNullOrEmpty($env:POINT_IN_TIME)){
        $dbPointinTime=$env:POINT_IN_TIME
    } else {
        $dbPointinTime = (Get-Date).AddMinutes(-7)
    }
    Write-Host "point in Time: $dbPointinTime"
    return $dbPointinTime
}
function GetDbInfo{
    Param ($dbi)
    $lv_dbname              = $dbi.DatabaseName
    $lv_resourceId          = $dbi.ResourceId
    $lv_edition = $dbi.Edition
    if ( $lv_edition -eq "Standard"){
        $lv_edition          = 'GeneralPurpose'
    }
    $lv_ServiceObjectiveName= $dbi.CurrentServiceObjectiveName
    if ( $lv_ServiceObjectiveName -eq "ElasticPool"){
        $lv_ServiceObjectiveName = 'GP_Gen5_2'
    }
    
    $lv_serverName          = $dbi.ServerName
    $lv_resourceGroupName   = $dbi.ResourceGroupName 
    $lv_ElasticPoolName     = $dbi.ElasticPoolName

    $dbinfo = @()

    $dbinfo += $lv_dbname
    $dbinfo += $lv_resourceId
    $dbinfo += $lv_edition
    $dbinfo += $lv_ServiceObjectiveName
    $dbinfo += $lv_serverName
    $dbinfo += $lv_resourceGroupName
    $dbinfo += $lv_ElasticPoolName

    return $dbinfo
}
function Restore{
    Param ($dbinfo, $dbnameTgt, [DateTime]$restorepoint)
    $dbname = $dbinfo[0]
    #$dbname
    $ResourceId=$dbinfo[1]
    #$ResourceId
    #$Edition=$dbinfo[2]
    #$Edition
    #$ServiceObjectiveName=$dbinfo[3]
    #$ServiceObjectiveName
    $ServerName=$dbinfo[4] 
    #$ServerName
    $ResourceGroupName=$dbinfo[5]
    #$ResourceGroupName
    $dbnameTgtName = $dbnameTgt[0]
    $elasticPool = $dbinfo[6]

    Write-Host "--- Db $dbname will be restored at that Time: $restorepoint on $dbnameTgtName"
    # Restore-AzSqlDatabase -FromPointInTimeBackup -PointInTime $restorepoint -ResourceGroupName $ResourceGroupName -ServerName $ServerName `
    #                       -TargetDatabaseName $dbnameTgtName -ResourceId $ResourceId -Edition $Edition -ServiceObjectiveName $ServiceObjectiveName `
    #                       -ElasticPoolName "Pool1" -WhatIf

    Restore-AzSqlDatabase -FromPointInTimeBackup -PointInTime  $restorepoint `
                          -ResourceGroupName $ResourceGroupName `
                          -ServerName $ServerName `
                          -TargetDatabaseName $dbnameTgtName `
                          -ResourceId $ResourceId `
                          -ElasticPoolName $elasticPool  # ` -WhatIf
}
function DeleteDb{
    Param($dbinfo)
    $dbname = $dbinfo[0]
    Write-Host "--- Delete Db $dbname"
    Remove-AzSqlDatabase `
        -ResourceGroupName $dbinfo[5] -ServerName $dbinfo[4] -DatabaseName $dbinfo[0] # ` -WhatIf
}
function CopyDb{
    Param($dbtgt, $dbsrc)
    # $dbtgt
    $dbsrcName = $dbsrc[0]
    $dbtgtName = $dbtgt[0]
    Write-Host "--- Copy Backup db $dbsrcName on $dbtgtName"
    New-AzSqlDatabaseCopy `
        -ResourceGroupName $dbtgt[5] `
        -ServerName $dbtgt[4] `
        -DatabaseName $dbsrcName `
        -CopyResourceGroupName $dbtgt[5] `
        -CopyServerName $dbtgt[4] `
        -ElasticPoolName $dbtgt[6] `
        -CopyDatabaseName $dbtgtName # ` -WhatIf
}
function RenameDB{
    Param($dbtgt, $dbsrc)
    $dbsrcName = $dbsrc[0]
    $dbtgtName = $dbtgt[0]
    Write-Host "--- Rename Db $dbsrcName to $dbtgtName "

    Set-AzSqlDatabase -ResourceGroupName $dbtgt[5]`
                      -ServerName $dbtgt[4] `
                      -DatabaseName $dbsrcName `
                      -NewName $dbtgtName
}
function DefaultEmptyParameter {
    Param ($parameter)

    if ([string]::IsNullOrEmpty($parameter)){
        $parameter = 'N'
    } else {
        $parameter = $parameter.toUpper()
    }
    return $parameter
}
function DefaultTagParameter {
    Param ($parameter)

    if ([string]::IsNullOrEmpty($parameter)){
        $parameter = 'N'
    } 
    return $parameter
}
function ValidateFTParameter {
    Param ($parameter, $parameterName ="")
    [System.Collections.ArrayList]$lv_y_list= @("Y", "X")

    if (![string]::IsNullOrEmpty($parameterName)){
        Write-Host "ValidateFTParameter for $parameterName"
    }

    $lv_inputParameter = $parameter

    if (![string]::IsNullOrEmpty($parameter)){
        if ( $parameter.Lengh -gt 1) {
            $parameter = 'N'
        } else {
            if ( $parameter.toUpper() -NotIn $lv_y_list ){
                $parameter = 'N'
            } else {
                $parameter = 'Y'
            }
            # if ( ( $parameter.toUpper() -ne 'Y' ) -or ( $parameter.toUpper() -ne 'X' ) ){
            #     $parameter = 'N'
            # }
        }
    } else {
        $parameter = 'N'
    }
    Write-Host "Input:" $lv_inputParameter 
    Write-Host "Output:" $parameter 

    return $parameter
}
Function Display-Log{
    #Display-Log $AzureLog "error" "There was an error with $cmd_PS0"
    Param ($IsAzure, $MsgType, $Msg)

    if ( $IsAzure -eq 'X' ){
        Switch ($MsgType)
        {
            error {Write-Host "##vso[task.logissue type=error] $Msg"} 
            command {Write-Host "##[command] $Msg"}
            section {Write-Host "##[section] $Msg"}
            debug {Write-Host "##[debug] $Msg"}
            warning {Write-Host "##[debug] $Msg"}
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

function GetPreviousEnvironment{
    Param(
        [string] $env
    )
    switch ($env.tolower()) {
        "dev" { $previousEnv = "tstnf" }
        "tstp" { $previousEnv = "dev" }
        "onb" { $previousEnv = "tstm" }
        "onbnf" { $previousEnv = "tstm" }
        "qa2" { $previousEnv = "onb" }
        "qas" { $previousEnv = "onb" }
        "prod" { $previousEnv = "qas" }
        "prd" { $previousEnv = "qas" }
        Default { $previousEnv = $env.tolower()}
    }
    return $previousEnv
}
function GetPreviousEnvironmentForWorkbench{
    Param(
        [string] $env
    )
    switch ($env.tolower()) {
        "prd" { $previousEnv = "tstnf" }
        Default { $previousEnv = $env.tolower()}
    }
    return $previousEnv
}
function GetPingUrl{
    Param(
        [string] $env,
        [string] $component,
        [string] $landscape = 'eu'
        )
    Write-Host "Building PingUrl based on the env=$env and the component=$component"
    switch ($env.tolower()) {
        "prod" { $envVal = "" }
        "prd" { $envVal = "" }
        "tsteu (01)" { $envVal = "-tst" }
        "tsteu(01)" { $envVal = "-tst" }
        "tst-01" { $envVal = "-tst" }
        "tst-02" { $envVal = "-tstnf" }
        "tst-03" { $envVal = "-tstm" }
        "tstnf (02)" { $envVal = "-tstnf" }
        "tstnf(02)" { $envVal = "-tstnf" }
        "tstm (03)" { $envVal = "-tstm" }
        "tstm(03)" { $envVal = "-tstm" }
        "tstp(04)" { $envVal = "-tstp" }
        "tstp (04)" { $envVal = "-tstp" }
        "tst-04" { $envVal = "-tstp" }
        "tst04" { $envVal = "-tstp" }
        "tst(05)" { $envVal = "-dev" }
        "tst (05)" { $envVal = "-dev" }
        "tst-05" { $envVal = "-dev" }
        "tst05" { $envVal = "-dev" }
        "tst(06)" { $envVal = "-devnx" }
        "tst (06)" { $envVal = "-devnx" }
        "tst-06" { $envVal = "-devnx" }
        "tst06" { $envVal = "-devnx" }
        "tst(07)" { $envVal = "-tstnx" }
        "tst (07)" { $envVal = "-tstnx" }
        "tst-07" { $envVal = "-tstnx" }
        "tst07" { $envVal = "-tstnx" }
         Default { $envVal = "-" + $env.tolower()}
    }

    switch ($landscape.tolower()){
        "eu" { $domain = "-internal.eu.hrx.alight.com" }
        "us" { $domain = "-internal.us.hrx.alight.com" }
        "us2" { $domain = "-internal.us2.hrx.alight.com" }
        "us3" { $domain = "-internal.us3.hrx.alight.com" }
    }

    switch ($component) {
        "CalcApi"  { $url= "https://calc-admin-api$envVal" + $domain  + "/ping" }
        "CalcUi"  { $url= "https://calc-admin$envVal" + $domain  + "/ping"}
        "PayApi"  { $url= "https://pay-api$envVal" + $domain  + "/ping" }
        "PayUi"   { $url= "https://pay$envVal" + $domain  + "/ping"}

        "EloiseAnomalyOrchestration" { $url= "https://eloise-orchestration$envVal" + $domain  + "/ping"}
        "EloiseApiClient" { $url= "https://eloise-client$envVal" + $domain  + "/ping"}
        "EloiseAPIIndividualPayAnomalyAI" { $url= "https://eloise-ipa$envVal" + $domain  + "/ping" }
        "EloiseApiPayanomaly" { $url= "https://eloise-payanomaly$envVal" + $domain  + "/ping" }
        #"EloiseAzureFunctions" { $url= "https://calc-admin-api$envVal" + $domain  + "/ping" }
        "EloiseMLBusinessRules" { $url= "https://eloise-ml-business-rules-engine$envVal" + $domain  + "/ping" }

        "EloiseXBackend" { $url= "https://eloise-api$envVal" + $domain  + "/ping"}
        "EloiseXUI" { $url= "https://eloise$envVal" + $domain  + "/ping"}

        "AssistFrontend" { $url= "https://assist$envVal" + $domain  + "/ping" }
        #AssistCoreApi does not exist for TSTm. Only available for TSTnf and the env is refered as "tst"
        #"AssistCoreApi" { $url= "https://assist-api$envVal" + $domain  + "/ping"}
        "AssistCoreApi" { $url= "https://assist-api-tst" + $domain  + "/ping" }

        "hrXAccess" { $url= "https://access$envVal" + $domain  + "/ping"}
        "hrXAccessAPI" { $url= "https://access-api$envVal" + $domain  + "/ping"}

        "hrXAiApi" {$url = "https://bot$envVal" +$domain + "/ping"}
        "hrXConfigApi" { $url= "https://config$envVal" + $domain  + "/ping"}
        "hrXDocApi" { $url= "https://doc$envVal" + $domain  + "/ping" }
        "hrXDocGenApi" { $url= "https://docgen$envVal" + $domain  + "/ping"}
        "hrXFormsApi" { $url= "https://forms$envVal" + $domain  + "/ping"}
        "hrXHelpCenter" { $url= "https://help$envVal" + $domain  + "/ping"}
        "hrXSafeboxApi" { $url= "https://safebox$envVal" + $domain  + "/ping" }
        #"hrXSafeboxAzure"
        "hrXTSLApi" { $url= "https://tsl$envVal" + $domain  + "/ping" }
        "hrXAdmin" { $url= "https://admin$envVal" + $domain  + "/ping" }
        #"hrXAnomalyDetectionApi" 
        "hrXIdentityApi" { $url= "https://identity$envVal" + $domain  + "/ping" }
        "hrXClientApi" { $url= "https://client$envVal" + $domain  + "/ping" }
        "hrXPeopleApi" { $url= "https://people-api$envVal" + $domain  + "/ping"}
        "hrXStart" { $url= "https://start$envVal" + $domain  + "/ping" }
        "hrXTranslationApi" { $url= "https://translation-api$envVal" + $domain  + "/ping" }
        #"hrXTranslationLabels"
        "hrXExtensionUI" { $url= "https://extensions$envVal" + $domain  + "/ping" }
        "hrXExtensionAPI" { $url= "https://extensions-api$envVal" + $domain  + "/ping" }
        "hrXTicketPrediction" { $url= "https://ml-api$envVal" + $domain  + "/ping" }
        #"hrXTicketPredictionMLPickledModelsMLZ" 
        #"hrXFormsAttachmentsFunctionsApi"
        #"hrXBodprocessorX"
        #"hrXNLOPDB"
        #"hrXNLOPFunctionApp"
        #"WebhooksEventHandlerApi"
        #"WebhooksEventHandlerConsumer"
        #"hrXUmbraco"
        "hrXTaxationTool" {  $url= "https://taxtool$envVal" + $domain  + "/ping" }
        #"hrXTaxationToolApi" {  $url= "https://taxtool$envVal" + $domain  + "/ping" }
        Default { Write-Warning "Please update function GetPingUrl for $component"}
    }
    return $url
}

function GetVersionFromPingUrl {
    Param ([string] $url,$component,$env)
    Write-Host "Getting version(tag) deployed for $component in $env, url = $url"
    try {
        $curlResponseJson   = Invoke-WebRequest $url -UseBasicParsing
        $curlResponseObject = ($curlResponseJson | ConvertFrom-Json).psobject
        $lv_version         = $curlResponseObject.Properties.Where({ $_.Name -eq 'version' })
        $lv_currentVersion  = $lv_version.value
    }
    catch {
        Write-Host $_
        $lv_currentVersion = ""
    }
    
    return $lv_currentVersion
}

function GetBuildDefinition{
    Param([String] $component)
    switch ($component.tolower()) {
        "CalcDb".tolower() { $definition=369 }
        "CalcUi".tolower() { $definition=357 }
        "CalcApi".tolower() { $definition=342 }
        "CalcWorkbench".tolower() { $definition=670 }
        "PayUi".tolower() { $definition=349 }
        "PayApi".tolower() { $definition=348 }
        "PayBodp".tolower() { $definition=405 }
        "EloiseAnomalyOrchestration".tolower() { $definition=296 }
        "EloiseApiClient".tolower() { $definition=287 }
        "EloiseAPIIndividualPayAnomalyAI".tolower() { $definition=300 }
        "EloiseApiPayanomaly".tolower() { $definition=285 }
        "EloiseAzureFunctions".tolower() { $definition=290 }
        "EloiseMLBusinessRules".tolower() { $definition=298 }
        "EloiseXMLFunctions".tolower() { $definition=566 }
        "EloiseXBackend".tolower() { $definition=521 }
        "EloiseXUI".tolower() { $definition=607 }
        "hrXAiAPI".tolower() { $definition=124 }
        "hrXConfigApi".tolower() { $definition=121 }
        "hrXDocApi".tolower() { $definition=265 }
        "hrXDocGenApi".tolower() { $definition=266 }
        "hrXFormsApi".tolower() { $definition=145 }
        "hrXAccess".tolower() { $definition=113 }
        "hrXAccessApi".tolower() { $definition=627 }
        "hrXHelpCenter".tolower() { $definition=140 }
        "hrXSafeboxApi".tolower() { $definition=138 }
        "hrXSafeboxAzure".tolower() { $definition=202 }
        "hrXTSLApi".tolower() { $definition=116 }
        "hrXAdmin".tolower() { $definition=257 }
        "hrXAnomalyDetectionApi".tolower() { $definition=224 }
        "hrXIdentityApi".tolower() { $definition=139 }
        "hrXClientApi".tolower() { $definition=374 }
        "hrXPeopleApi".tolower() { $definition=891 }
        "hrXStart".tolower() { $definition=255 }
        "hrXTranslationApi".tolower() { $definition=377 }
        "hrXTranslationLabels".tolower() { $definition=380 }

        "AssistFrontend".tolower() { $definition=188 }
        "AssistCoreApi".tolower() { $definition=208 }
        "AdminLayer".tolower() { $definition=107 }
        "AssistRTH".tolower() { $definition=114 }
        "AntivirusICAP".tolower() { $definition=315 }
        "ScheduleFunctions".tolower() { $definition=356 }
        "AttachmentFunctions".tolower() { $definition=365 }

        "hrXExtensionUI".tolower() { $definition=688 }
        "hrXExtensionAPI".tolower() { $definition=681 }

        "hrXTicketPrediction".tolower() { $definition=110 }
        "hrXTicketPredictionMLPickledModelsMLZ".tolower() { $definition=557 }
        "hrXFormsAttachmentsFunctionsApi".tolower() { $definition=843 }
        "hrXBodprocessorX".tolower() { $definition=857 }
        "hrXNLOPDB".tolower() { $definition=865 }
        "hrXNLOPFunctionApp".tolower() { $definition=868 }
        "WebhooksEventHandlerAPI".tolower() { $definition=892 }
        "WebhooksEventHandlerConsumer".tolower() { $definition=905 } 
        "hrXUmbraco".tolower() { $definition=777 } 
        "hrXTaxationTool".tolower() { $definition=714 } 
        "hrXTaxationToolApi".tolower() { $definition=734 }

        Default { Write-Host "Please update function GetBuildDefinition for $component.tolower()"; exit 1}
    }
    return $definition
}

function GetBuildNumbersForTag {
    Param([string]$tag="22.3.0", [string] $component="CalcApi", [string] $definition="342")
    Write-Host "Looking for the buildNumber linked to the tag $tag for component $component"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "$lv_basicAuth")
    $headers.Add("Cookie", "VstsSession=%7B%22PersistentSessionId%22%3A%227687a07e-b816-4e84-ba19-f5d9d1c9dac1%22%2C%22PendingAuthenticationSessionId%22%3A%2200000000-0000-0000-0000-000000000000%22%2C%22CurrentAuthenticationSessionId%22%3A%2200000000-0000-0000-0000-000000000000%22%2C%22SignInState%22%3A%7B%7D%7D; X-VSS-UseRequestRouting=True")
    
    $response = Invoke-RestMethod "https://dev.azure.com/ProdNGAHR/HR%20Portfolio/_apis/build/builds?definitions=$definition" -Method 'GET' -Headers $headers
    $response = $response | ConvertTo-Json

    $lv_sourceBranch = "refs/tags/" + $tag
    
    $listOfBuild = ($response | ConvertFrom-Json).psobject.Properties.Value.Where({ $_.sourceBranch -eq $lv_sourceBranch })
    # $listOfBuild.ForEach({ [pscustomobject] @{ "buildnumber" = $_.buildNumber } }) | ConvertTo-Json
    #$listOfBuild
    # Write-Host "not sorted"
    $listOfBuildNumber = $listOfBuild.buildNumber 
    # $listOfBuildNumber 
    # Write-Host "sorted"
    $listOfBuildNumberSorted = $listOfBuildNumber | Sort-Object
    # $listOfBuildNumberSorted 
    # Write-Host "Get Latest"
    $LatestBuild = $listOfBuildNumberSorted | Select-Object -Last 1
    #$LatestBuild
    return $LatestBuild
}

#GetBuildNumbersForTag -tag "22.4.5" -component "PayBodp" -definition "557"

function GetBuildIdForTag {
    Param([string]$tag="22.3.0", [string] $component="CalcApi", [string] $definition="342")
    Write-Host "Looking for the buildid linked to the tag $tag for component $component"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "$lv_basicAuth")
    $headers.Add("Cookie", "VstsSession=%7B%22PersistentSessionId%22%3A%227687a07e-b816-4e84-ba19-f5d9d1c9dac1%22%2C%22PendingAuthenticationSessionId%22%3A%2200000000-0000-0000-0000-000000000000%22%2C%22CurrentAuthenticationSessionId%22%3A%2200000000-0000-0000-0000-000000000000%22%2C%22SignInState%22%3A%7B%7D%7D; X-VSS-UseRequestRouting=True")
    $response = Invoke-RestMethod "https://dev.azure.com/ProdNGAHR/HR%20Portfolio/_apis/build/builds?definitions=$definition" -Method 'GET' -Headers $headers
    $response = $response | ConvertTo-Json
    $lv_sourceBranch = "refs/tags/" + $tag
    $listOfBuild = ($response | ConvertFrom-Json).psobject.Properties.Value.Where({ $_.sourceBranch -eq $lv_sourceBranch })
    $listOfBuildId = $listOfBuild.id 
    $listOfBuildIdSorted = $listOfBuildId | Sort-Object
    $LatestBuildId = $listOfBuildIdSorted | Select-Object -Last 1
    return $LatestBuildId
}

function GetResourceGroupName {
    Param([String] $component, [string] $env)
    Write-Host "Retrieving the ResourceGroupName for component=$component in the env=$env"
    if (![string]::IsNullOrEmpty($component)){
        if ( $component.tolower() -like "*pay*" ){
            switch ($env.tolower()) {
                dev { $lv_resourceGroupName = "rg-nga-d-cus-pay-01" }
                tst { $lv_resourceGroupName = "rg-alg-t-weu-hrxpay-01" }
                tstnf { $lv_resourceGroupName = "rg-alg-t-weu-hrxpay-02" }
                tstm { $lv_resourceGroupName = "rg-alg-t-weu-hrxpay-03" }
                onb { $lv_resourceGroupName = "rg-alg-o-weu-hrxpay-01" }
                qas { $lv_resourceGroupName = "rg-alg-q-weu-hrxpay-01" }
                prd { $lv_resourceGroupName = "rg-alg-p-weu-hrxpay-01" }
                Default { write-Host "[ERROR][GetResourceGroupName] - the env is not defined as expected"; exit 2}
            }
        } 
        if ( $component.tolower() -like "*calc*" ){
            switch ($env.tolower()) {
                dev { $lv_resourceGroupName = "rg-nga-d-cus-calc-01" }
                tst { $lv_resourceGroupName = "rg-alg-t-weu-hrxcalc-01" }
                tstnf { $lv_resourceGroupName = "rg-alg-t-weu-hrxcalc-02" }
                tstm { $lv_resourceGroupName = "rg-alg-t-weu-hrxcalc-03" }
                onb { $lv_resourceGroupName = "rg-alg-o-weu-hrxcalc-01" }
                qas { $lv_resourceGroupName = "rg-alg-q-weu-hrxcalc-01" }
                prd { $lv_resourceGroupName = "rg-alg-p-weu-hrxcalc-01" }
                Default { write-Host "[ERROR][GetResourceGroupName] - the env is not defined as expected"; exit 3}
            }
        }
        if ( $component.tolower() -like "*eloise*" ){
            switch ($env.tolower()) {
                dev { $lv_resourceGroupName = "nga-d-weu-cluster-01-aks" }
                tst { $lv_resourceGroupName = "rg-alg-t-weu-hrxcore-01" }
                tstnf { $lv_resourceGroupName = "rg-alg-t-weu-hrxcore-02" }
                tstm { $lv_resourceGroupName = "rg-alg-t-weu-hrxcore-03" }
                onb { $lv_resourceGroupName = "rg-alg-o-weu-hrxcore-01" }
                qas { $lv_resourceGroupName = "rg-alg-q-weu-hrxcore-01" }
                prd { $lv_resourceGroupName = "rg-alg-p-weu-hrxcore-01" }
                Default { write-Host "[ERROR][GetResourceGroupName] - the env is not defined as expected"; exit 3}
            }
        }
    } else {
        write-Host "[ERROR][GetResourceGroupName] - the component is not defined"
        exit 1
    }
    Write-Host "Retrieved ResourceGroupName=$lv_resourceGroupName"
    return $lv_resourceGroupName
}

function GetSQLServerName {
    Param([String] $component, [string] $env)
    Write-Host "Retrieving the SQLServerName for component=$component in the env=$env"
    if (![string]::IsNullOrEmpty($component)){
        if ( $component.tolower() -like "*pay*" ){
            switch ($env.tolower()) {
                dev { $lv_SqlServerName = "sql-nga-d-cus-pay-01" }
                tst { $lv_SqlServerName = "sql-alg-t-weu-hrxpay-01" }
                tstnf { $lv_SqlServerName = "sql-alg-t-weu-hrxpay-02" }
                tstm { $lv_SqlServerName = "sql-alg-t-weu-hrxpay-03" }
                onb { $lv_SqlServerName = "sql-alg-o-weu-hrxpay-01" }
                qas { $lv_SqlServerName = "sql-alg-q-weu-hrxpay-01" }
                prd { $lv_SqlServerName = "sql-alg-p-weu-hrxpay-01" }
                Default { write-Host "[ERROR][GetSQLServerName] - the env is not defined as expected"; exit 2}
            }
        } 
        if ( $component.tolower() -like "*calc*" ){
            switch ($env.tolower()) {
                dev { $lv_SqlServerName = "hrxcalc-dev" }
                tst { $lv_SqlServerName = "sql-alg-t-weu-hrxcalc-01" }
                tstnf { $lv_SqlServerName = "sql-alg-t-weu-hrxcalc-02" }
                tstm { $lv_SqlServerName = "sql-alg-t-weu-hrxcalc-03" }
                onb { $lv_SqlServerName = "sql-alg-o-weu-hrxcalc-01" }
                qas { $lv_SqlServerName = "sql-alg-q-weu-hrxcalc-01" }
                prd { $lv_SqlServerName = "sql-alg-p-weu-hrxcalc-01" }
                Default { write-Host "[ERROR][GetSQLServerName] - the env is not defined as expected"; exit 3}
            }
        }
        if ( $component.tolower() -like "*eloise*" ){
            switch ($env.tolower()) {
                dev { $lv_SqlServerName = "nga-d-weu-eloise-04-db" }
                tst { $lv_SqlServerName = "sql-alg-t-weu-eloise-01" }
                tstnf { $lv_SqlServerName = "sql-alg-t-weu-eloise-02" }
                tstm { $lv_SqlServerName = "sql-alg-t-weu-eloise-03" }
                onb { $lv_SqlServerName = "sql-alg-o-weu-eloise-01" }
                qas { $lv_SqlServerName = "sql-alg-q-weu-eloise-01" }
                prd { $lv_SqlServerName = "sql-alg-p-weu-eloise-01" }
                Default { write-Host "[ERROR][GetSQLServerName] - the env is not defined as expected"; exit 3}
            }
        }
    } else {
        write-Host "[ERROR][GetSQLServerName] - the component is not defined"
        exit 1
    }
    Write-Host "Retrieved SqlServerName=$lv_SqlServerName"
    return $lv_SqlServerName
}

function DefineAsEnvVar {
    #Param([String] $var, [string] $value, [string] $variableFile, [boolean] $isSecreat=$false, [boolean] $isOutput=$true)
    Param([String] $var, [string] $value, [string] $variableFile)

    #Write-Host "##vso[task.setvariable variable=$var;isSecret=false;isOutput=true;]$value"
    [Environment]::SetEnvironmentVariable("PREP_$var",$value)
    Write-Host "##vso[task.setvariable variable=PREP_$var]$value"
    Write-Host "##vso[task.setvariable variable=$var;isSecret=false;isOutput=true]$value"

    if (![string]::IsNullOrEmpty($variableFile)){
        AddToFile $var $value $variableFile
    }
}
function AddToFile {
    Param ([string] $variable="Variables", [string] $value="VariableValues", [string] $file="testFile.txt")
    $lv_varName = "PREP_" + $variable
    Add-Content -Value "`$$lv_varName='$value'" -Path $file
}

function AddToFileHeader {
    Param ([string] $header="#Declaration of External variables", [string] $file="testFile.txt")
    Add-Content -Value $header -Path $file
}

function DefineEnvVarTestData {
    Param ([string]$isAzure="")

    if ([string]::IsNullOrEmpty($isAzure)){
        $isAzure = 'N'
    }

    if ( $isAzure.toUpper() -eq 'N' ) {
        Write-Host "Using Test EnvVars"
        $env:_DEPLOYMODE        = "ft"
        $env:DEPLOY_CALC_API    = "y"
        $env:DEPLOY_CALC_UI     = "berezrze"
        $env:DEPLOY_CALC_DB     = ""
        $env:DEPLOY_PAY_API     = "Y"
        $env:DEPLOY_PAY_UI      = "Y"
        $env:RELEASE_RELEASEID  = "32612"
        $env:RELEASE_ENVIRONMENTNAME = "TSTNF"
        $env:RELEASE_ATTEMPTNUMBER = "2"
        $env:DEPLOY_RELEASE     = "23.2.0-rc1"
    } else {
        Write-Host "Using EnvVars from pipeline"
    }
}

function DefineExtVarFile{
    Param([String] $scriptFolder, [String] $lv_releaseId, [String] $lv_releaseEnvName, [String] $lv_releaseAttempt, [String] $lv_component = "PayCalc")
    $VarFileName = "$scriptFolder\$lv_component\ExtVars\VariablesFiles_" + $lv_releaseId + "_" + $lv_releaseEnvName + "_" + $lv_releaseAttempt + ".ps1"
    return $VarFileName
}

function DefineGlrepFile{
    Param([String] $scriptFolder, [String] $lv_releaseId, [String] $lv_releaseEnvName, [String] $lv_releaseAttempt, [String] $lv_component = "PayCalc")
    #$VarFileName = "$scriptFolder\$lv_component\Glrep\$lv_releaseId" + "_" + $lv_releaseEnvName + ".csv"
    $VarFileName = "$scriptFolder\$lv_component\Glrep\$lv_releaseEnvName" + ".csv"
    return $VarFileName
}

function DefineVarFile{
    Param([String] $scriptFolder, [String] $lv_releaseId, [String] $lv_releaseEnvName, [String] $lv_releaseAttempt, [String] $lv_component = "PayCalc")
    $VarFileName = "$scriptFolder\$lv_component\VarComparison\$lv_releaseEnvName" + ".csv"
    return $VarFileName
}

function DefineGlrepFileFolder{
    Param([String] $scriptFolder, [String] $lv_releaseEnvName, [String] $lv_component = "PayCalc")
    $GlrepFileFolder = "$scriptFolder\$lv_component\Glrep\$lv_releaseEnvName"
    return $GlrepFileFolder
}

function DefineVarFileFolder{
    Param([String] $scriptFolder, [String] $lv_releaseEnvName, [String] $lv_component = "PayCalc")
    $VarFileFolder = "$scriptFolder\$lv_component\VarComparison\$lv_releaseEnvName"
    return $VarFileFolder
}

function GitAction {
    Param([string] $action, [string] $message="Push External Var File", [string] $branch="main", [string] $files="PayCalc/ExtVars/*")
    git config user.email "products.jenkins@ngahr.com"
    git config user.name "BundlePipeline"
    git config pull.ff only
    Get-Location
    Write-Host "Git $action" -ForegroundColor Yellow
    switch ($action.tolower()) {
        "fetch" { git fetch }
        "pull" { git pull }
        "push" {  git add $files; git commit -m $message; git push origin $branch --force }
        "checkout" { git checkout $branch }
    }
}

function GetSubscriptionID {
    Param ([String] $env, [String] $landscape="EU")
    $landscapeEnv = $landscape + "-" + $env
    $landscapeEnv = $landscapeEnv.toUpper()

    switch ($landscapeEnv) {
        "EU-DEV" { $lv_subscriptionID="b4f2776f-c325-4a6b-ac07-548234e77e83" }
        "EU-TST" { $lv_subscriptionID="d46f1336-54a1-40ab-a6d4-2dd115fa4089" }
        "EU-TSTM" { $lv_subscriptionID="d46f1336-54a1-40ab-a6d4-2dd115fa4089" }
        "EU-TSTNF" { $lv_subscriptionID="d46f1336-54a1-40ab-a6d4-2dd115fa4089" }
        "EU-ONB" { $lv_subscriptionID="0b4fe42a-537c-4a60-8bea-9bab68ce2099" }
        "EU-QAS" { $lv_subscriptionID="88b0b729-3181-4ee1-9393-8ba2f5d5182b" }
        "EU-PRD" { $lv_subscriptionID="d46f1336-54a1-40ab-a6d4-2dd115fa4089" }
        "US-ONB" { $lv_subscriptionID="42e8f40b-dddb-4110-9d26-49d7c3af878c" }
        "US-QAS" { $lv_subscriptionID="200bcb84-b968-4ccd-83c5-8d0a791bdd0b" }
        "US-PRD" { $lv_subscriptionID="84a4d0f0-38e9-4319-ad51-1e2800fe3401" }
        "US3-ONB" { $lv_subscriptionID="37adcf3c-7e90-48cc-8937-660d68df786b" }
        "US3-QAS" { $lv_subscriptionID="3eb2b3a6-a3e2-41b6-95b0-a7ab5969ba98" }
        "US3-PRD" { $lv_subscriptionID="0bce3552-f3ca-4eba-93d9-9e3111e51dc8" }
        Default { Write-Host "Please Provide an Environment"; exit 1 }
    }
    Write-Host "SubscriptionID: " $lv_subscriptionID
    Write-Host "Environment: " $landscapeEnv
    return $lv_subscriptionID
}

function SetGccToTest {
    Param ([string] $env)

    switch ($env.tolower()) {
        'dev' {$lv_gcc = 'z05' }
        'devnf' {$lv_gcc = 'z01' }
        'devm' {$lv_gcc = 'z05' }
        'tst' { $lv_gcc = 'zza' }
        'tstnf' { $lv_gcc = 'z01' }
        'tstp' { $lv_gcc = 'zza' }
        'tstm' { $lv_gcc = 'zza' }
        'onb' { $lv_gcc = 'zza' }
        'qas' { $lv_gcc = 'zza' }
        'prd' { $lv_gcc = 'zza' }
        Default { Write-Host "A valid environmennt should be provided"; exit 1 }
    }
    return $lv_gcc
}

function SetEnvToTest {
    Param ([string] $env, [string] $ShortName="")

    if ( $ShortName -eq 'Y' ){
        switch ($env.tolower()) {
            'dev' { $lv_env = 'dev' }
            'devnf' { $lv_env = 'dev' }
            'devm' { $lv_env = 'dev' }
            'tst' { $lv_env = 'tst' }
            'tstnf' { $lv_env = 'tst' }
            'tstm' { $lv_env = 'tst' }
            'tstp' { $lv_env = 'tst' }
            'onb' { $lv_env = 'onb' }
            'qas' { $lv_env = 'qas' }
            'prd' { $lv_env = 'prd' }
            Default { Write-Host "A valid environmennt should be provided"; exit 1 }
        }
    } else {
        switch ($env.tolower()) {
            'dev' { $lv_env = 'dev' }
            'devnf' { $lv_env = 'devnf' }
            'devm' { $lv_env = 'devm' }
            'tst' { $lv_env = 'tst' }
            'tstp' { $lv_env = 'tstp' }
            'tstnf' { $lv_env = 'tstnf' }
            'tstm' { $lv_env = 'tstm' }
            'onb' { $lv_env = 'onb' }
            'qas' { $lv_env = 'qas' }
            'prd' { $lv_env = 'prd' }
            Default { Write-Host "A valid environmennt should be provided"; exit 1 }
        }
    }
    return $lv_env
}
function GetManualStepOutput {
    Param( [string] $releaseId="32984",[string] $environmentId="101581",[string] $attempt="1",[string] $stepName="Manual Validation",[string] $apiVersion="api-version=6.0")
    Write-Host "Retrieving the User choice in ManualStep for ReleaseId=$releaseId, EnvironmentiD=$environmentId, Attempt=$attempt"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "$lv_basicAuth")
    $headers.Add("Cookie", "VstsSession=%7B%22PersistentSessionId%22%3A%227687a07e-b816-4e84-ba19-f5d9d1c9dac1%22%2C%22PendingAuthenticationSessionId%22%3A%2200000000-0000-0000-0000-000000000000%22%2C%22CurrentAuthenticationSessionId%22%3A%2200000000-0000-0000-0000-000000000000%22%2C%22SignInState%22%3A%7B%7D%7D; X-VSS-UseRequestRouting=True")
    
    $lv_url = "https://vsrm.dev.azure.com/ProdNGAHR/HR%20Portfolio/_apis/Release/releases/" + $releaseId + "?api-version=6.0"
    # $lv_url 
    $response = Invoke-RestMethod "$lv_url" -Method 'GET' -Headers $headers
    # $response
    $response = $response | ConvertTo-Json -Depth 10

    $environmentInfo = ($response | ConvertFrom-Json).psobject.Properties.Where({ $_.Name -eq "environments" })
    $allEnv = $environmentInfo.Value
    # Write-Host "allEnv"
    # $allEnv
    $specificEnv = $allEnv.Where({ $_.id -eq $environmentId })
    # Write-Host "specificEnv"
    # $specificEnv 
    $deploymentSteps        = $specificEnv.deploySteps
    # Write-Host "deploymentSteps"
    # $deploymentSteps

    if ( $attempt -eq 1 ){
        $releaseDeployPhases    = $deploymentSteps.releaseDeployPhases
    } else {
        $attemptSpecific        = $deploymentSteps.Where({ $_.attempt -eq $attempt })
        $releaseDeployPhases    = $attemptSpecific.releaseDeployPhases
    }

    try {
        # Write-Host "releaseDeployPhases"
        # $releaseDeployPhases
        $lv_stepDetails         = $releaseDeployPhases.Where({ $_.name -eq $stepName })
        $lv_step_status         = $lv_stepDetails.status
    }
    catch {
        Write-Host $_
        $lv_step_status = 'error'
    }
    Write-Host "Status of Step $stepName : $lv_step_status"
    return $lv_step_status
}

function isDeploymentNeeded {
    Param([string] $p_dep_requested, [string] $p_current_build, [string] $p_requested_build, [string] $p_component)
    if ( $p_dep_requested -eq 'Y' ){
        if ( $p_current_build -eq $p_requested_build ){
            $lv_deploymentNeeded ='N'
            Write-Host "This is already the build deployed for $p_component, skipping deployment"
        } else {
            $lv_deploymentNeeded ='Y'
        }
    } else {
        Write-Host "The deployment is not requested for $p_component"
        $lv_deploymentNeeded ='N'
    }
    return $lv_deploymentNeeded
}

function kubectlGetInfo {
    param (
        [string] $p_deployment="hrx-access",
        [string] $p_information="image"
        )
                    # 
    switch ($p_information) {
        image { $jsonpath="{..image}" }
        resources { $jsonpath="{..resources}" }
        Default { Write-Host "Only implemented for Image"; exit 1}
    }
    Write-Host "kubectl get deployment $p_deployment -o jsonpath=$jsonpath"
    $lv_kubectlInfo = kubectl get deployment $p_deployment -o jsonpath=$jsonpath

    switch ($p_information) {
        image { $lv_kubectlInfo = $lv_kubectlInfo.split(":")[1] }
        Default { Write-Host "Only implemented for Image"; exit 1}
    }
    return $lv_kubectlInfo
}

function kubectlSetNamespace {
    param (
        [string] $p_env="tstnf"
    )
    Write-Host "kubectl config set-context --current --namespace=$p_env"
    kubectl config set-context --current --namespace=$p_env
}

# Function DisplayEnvVar{
#     Param ([string] $p_varname)
#     $lv_varnameUpper = $p_varname.toupper()
#     $lv_prep_varname = "PREP_" + $lv_varnameUpper
#     Write-Host $lv_prep_varname  $env:"$lv_prep_varname"
# }

function SetLocalDefaultReleasesToDeploy{
    Write-Host "Running Locally Set Local Default Releases"
    $env:DEPLOY_RELEASE = "23.2.0-rc1"
    $env:DEPLOY_RELEASE_PAYAPI = "23.1.0"
    $env:DEPLOY_RELEASE_PAYUI = "23.1.1"
    #$env:DEPLOY_RELEASE_PAYBODP = "23.1.2"
    $env:DEPLOY_RELEASE_CALCAPI = "23.1.3"
    $env:DEPLOY_RELEASE_CALCUI = "23.1.4"
    $env:DEPLOY_RELEASE_CALCDB = "23.1.5"
}

function checkRCtag {
    #This function will check if rc string present in the tag.If exists then abort the deployment for ONB,QAS & PRD
    param (
        [string] $tag="23.2.0-rc1",
        [string] $env="ONB"
        )

    switch ($env.tolower()) {
        'dev' { 
            Write-Host "rc tag  $tag allowed in $env";
            return 
        }
        'devnf' { 
            Write-Host "rc tag  $tag allowed in $env"; 
            return 
        }
        'devm' { 
            Write-Host "rc tag  $tag allowed in $env"; 
            return 
        }
        'tst' { 
            Write-Host "rc tag  $tag allowed in $env";
            return 
        }
        'tstnf' { 
            Write-Host "rc tag  $tag allowed in $env";
            return 
        }
        'tstm' { 
            Write-Host "rc tag  $tag allowed in $env"; 
            return 
        }
        'onb' { Write-Host "Validate rc tag $tag in $env"; }
        'qas' { Write-Host "Validate rc tag $tag in $env"; }
        'prd' { Write-Host "Validate rc tag $tag in $env"; }
        Default { Write-Host "A valid environmennt should be provided in checkRCtag function"; exit 1 }
    }    

    if ($tag -match "[a-zA-Z]")
    {
        Write-Host ("****ERROR:tag $tag contains aphabets in $env");                  
        Write-Host ("****ERROR:Please Ensure tag should be  non-rc like 22.2.0 for $env");
        $exit_code = 'Y'
    } else {
        Write-Host ("tag $tag NOT contains aphabets in $env")
        $exit_code = 'N'
    } 
    return $exit_code   
}

function GetTagStatusForBuildId {
    Param( [string] $component="CalcAdminUI", [string] $BuildId="150656" , [string] $checktag="readytstm")
    Write-Host "Looking for the BuildTAGs linked to the BuildID $BuildId for component $component"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "$lv_basicAuth")   
    $headers.Add("Cookie", "VstsSession=%7B%22PersistentSessionId%22%3A%227687a07e-b816-4e84-ba19-f5d9d1c9dac1%22%2C%22PendingAuthenticationSessionId%22%3A%2200000000-0000-0000-0000-000000000000%22%2C%22CurrentAuthenticationSessionId%22%3A%2200000000-0000-0000-0000-000000000000%22%2C%22SignInState%22%3A%7B%7D%7D; X-VSS-UseRequestRouting=True")
    
    Write-Host "Invoke-RestMethod https://dev.azure.com/ProdNGAHR/HR%20Portfolio/_apis/build/builds/$BuildId/tags?api-version=6.0"
    $response = Invoke-RestMethod "https://dev.azure.com/ProdNGAHR/HR%20Portfolio/_apis/build/builds/$BuildId/tags?api-version=6.0" -Method 'GET' -Headers $headers
    $buildTags = $response.value
    Write-Host "Build Tags : $buildTags "
    $checktagLower = $checktag.ToLower()
    Foreach ($buildTag in $buildTags) { 
        $buildTagLower = $buildTag.tolower()  
        if ( $buildTagLower -eq $checktagLower){
            $buildTagStatus = 'Y'
            return $buildTagStatus
        } else {
            $buildTagStatus = 'N'    
        }             
    }
    return $buildTagStatus
}
Function Encode-clientSecret{
    $EncodeSecret = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($clientSecret))
    Set-Variable -Name clientSecretenc -Value ($EncodeSecret) -Scope Global
}
Function Decode-clientSecret{
    $DecodeSecret = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($clientSecretenc))
    Set-Variable -Name clientSecret -Value ($DecodeSecret) -Scope Global
}

Function UrlencodeSecret {
    Param ([string] $clientSecretb64, [boolean] $urlEncode = $true)
    $clientSecretdec = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($clientSecretb64)) 
    Add-Type -AssemblyName System.Web
    if ( $urlEncode -eq $true ){
        $clientSecretUrlEnc = [System.Web.HttpUtility]::UrlEncode($clientSecretdec)
    } else {
        $clientSecretUrlEnc = $clientSecretdec
    }
    return $clientSecretUrlEnc
}
function GetIdentityTokenUser {
    Param ($clientID, $clientSecret, $identityUrl, $lv_userName, $lv_userPass)
    $lv_scope = 'identity_api.config_read%20identity_api.user_read%20pay_api.payroll_read%20pay_api.payroll_write%20pay_proxy'
    #$lv_scope = 'identity_api.config_read%20identity_api.config_write%20identity_api.user_read%20identity_api.user_write%20offline_access%20openid%20profile%20pay_api.payroll_read%20pay_api.payroll_write%20pay_proxy'
    Add-Type -AssemblyName System.Web

    Write-Host "Get User Identity Token"
    $identityTokenUrl = $identityUrl + "/connect/token"
    Write-Host $identityTokenUrl
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/x-www-form-urlencoded; charset=utf-8")
    $body ="client_id=$clientID&client_secret=$clientSecret&grant_type=password&scope=$lv_scope&username=$lv_userName&password=$lv_userPass"
    Write-Host "body: $body"
    $response = Invoke-RestMethod "$identityTokenUrl" -Method 'POST' -Headers $headers -Body $body
    $responseJson = $response  | ConvertTo-Json
    $token = ($responseJson | ConvertFrom-JSON | Select-Object access_token).access_token
    return $token
}
function GetIdentityTokenUser_2 {
    Param ($clientID, $clientSecret, $identityUrl)
    
    #$lv_scope = 'identity_api.config_read%20identity_api.config_write%20identity_api.user_read%20identity_api.user_write%20offline_access%20openid%20profile%20pay_api.payroll_read%20pay_api.payroll_write%20pay_proxy'
    Add-Type -AssemblyName System.Web

    Write-Host "Get User Identity Token"
    $identityTokenUrl = $identityUrl + "/connect/token"
    #Write-Host $identityTokenUrl
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/x-www-form-urlencoded; charset=utf-8")
    $body ="client_id=$clientID&client_secret=$clientSecret&grant_type=client_credentials"
    #Write-Host "body: $body"
    $response = Invoke-RestMethod "$identityTokenUrl" -Method 'POST' -Headers $headers -Body $body
    $responseJson = $response  | ConvertTo-Json
    $token = ($responseJson | ConvertFrom-JSON | Select-Object access_token).access_token
    return $token
}

function Retry-Command {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Position=1, Mandatory=$false)]
        [int]$Maximum = 5,

        [Parameter(Position=2, Mandatory=$false)]
        [int]$Delay = 30
    )

    Begin {
        $cnt = 0
    }

    Process {
        do {
            $cnt++
            try {
                # If you want messages from the ScriptBlock
                # Invoke-Command -Command $ScriptBlock
                # Otherwise use this command which won't display underlying script messages
                $ScriptBlock.Invoke()
                return
            } catch {
                Write-Error $_.Exception.InnerException.Message -ErrorAction Continue
                Start-Sleep -Seconds $Delay
            }
        } while ($cnt -lt $Maximum)

        # Throw an error after $Maximum unsuccessful invocations. Doesn't need
        # a condition, since the function returns upon successful invocation.
        throw 'Execution failed.'
    }
}
function GetBuildInfo_CalcDB_PayBodp {
    Param([string]$env="tst" ,  [string]$component="calcdb")
    #$lv_basicAuth =  $AuthorizationToken
    #$lv_basicAuth = "Basic cHJvZHVjdHMuamVua2luc0BuZ2Foci5jb206N3Q1Ynp3NXV3d2tpZXd2ZDRpdGZxam9ndWhkbWh4d29sNDV6bDN4N3Vwams0dGh6Mnp6YQ=="    
    $buildArray = @()
    #$lv_baseUrl = "https://dev.azure.com/ProdNGAHR/HR%20Portfolio"
    #ReleasePipeline DefinitionID of hrX Calc Database is 512
    $definitionId="512"
    #EnvironmentDefintionID of hrX Calc Database release pipeline
    switch ($component.tolower()){ 
      "calcdb" {
        $definitionId="512"
        switch ($env.tolower()){
          "tst" {
            $definitionEnvironmentId="1846"
          }
          "tstm" {
            $definitionEnvironmentId="2192"
          }
          "tstnf" {
            $definitionEnvironmentId="2191"
          }
          "onb" {
            $definitionEnvironmentId="1854"
          }
          "qas" {
            $definitionEnvironmentId="1855"
          }
          "prd" {
            $definitionEnvironmentId="1856"
          }      
          Default { Write-Host "please define the environment $env for definitionEnvironmentId" }      
        }
  
      }
      "paybodp" {
        $definitionId="557"
        switch ($env.tolower()){
          "tst" {
            $definitionEnvironmentId="2068"
          }
          "tstm" {
            $definitionEnvironmentId="2229"
          }
          "tstnf" {
            $definitionEnvironmentId="2228"
          }
          "onb" {
            $definitionEnvironmentId="2230"
          }
          "qas" {
            $definitionEnvironmentId="2219"
          }
          "prd" {
            $definitionEnvironmentId="2221"
          }      
          Default { Write-Host "please define the environment $env for definitionEnvironmentId" }      
        }
      }    
      Default { Write-Host "please define the component $component for either calcdb or paybodp" }
    }
  
    Write-Host "Looking for the Tag linked for component $component"
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "$lv_basicAuth")
    $headers.Add("Cookie", "VstsSession=%7B%22PersistentSessionId%22%3A%220495125e-6aa4-4f20-9ee9-41324f2b03c2%22%2C%22PendingAuthenticationSessionId%22%3A%2200000000-0000-0000-0000-000000000000%22%2C%22CurrentAuthenticationSessionId%22%3A%2200000000-0000-0000-0000-000000000000%22%2C%22SignInState%22%3A%7B%7D%7D")
  
    Write-Host "https://vsrm.dev.azure.com/ProdNGAHR/HR%20Portfolio/_apis/release/deployments?definitionId=$definitionId&definitionEnvironmentId=$definitionEnvironmentId&deploymentStatus=succeeded&latestAttemptsOnly=true&api-version=7.1-preview.2&`$top=1"
  
    $response = Invoke-RestMethod "https://vsrm.dev.azure.com/ProdNGAHR/HR%20Portfolio/_apis/release/deployments?definitionId=$definitionId&definitionEnvironmentId=$definitionEnvironmentId&deploymentStatus=succeeded&latestAttemptsOnly=true&api-version=7.1-preview.2&`$top=1" -Method 'GET' -Headers $headers
  
    if ( $component -eq "calcdb" ) {
            #$response | ConvertTo-Json
        Write-Host "definitionId:$definitionId"
        Write-Host "definitionEnvironmentId:$definitionEnvironmentId"
        $buildId = $response.psobject.Properties.Value.release.artifacts.definitionReference.version.id
        Write-Host "buildId:$buildId"
        Write-Host "buildId.count: ", $buildId.count
        if ($buildId.count -gt 1){
          #$buildId = $buildId.split(" ")
          $buildArray += $buildId[1]
          Write-Host ("buildId of $component is:$buildId[1]")
        } else {
          $buildArray += $buildId
          Write-Host ("buildId of $component is:$buildId")
        }      
        #Write-Host ("buildId of $component is:$buildId")
        #$buildArray += $buildId
    
        $buildNumber =  $response.psobject.Properties.Value.release.artifacts.definitionReference.version.name
        Write-Host $buildNumber.count
        if ($buildNumber.count -gt 1){
          #$buildNumber = $buildNumber.split(" ")
          $buildArray += $buildNumber[1]
          Write-Host ("buildId of $component is:$buildNumber[1]")
        } else {
          $buildArray += $buildNumber
          Write-Host ("buildId of $component is:$buildNumber")
        }      
        #Write-Host ("buildNumber of $component is:$buildNumber")
        #$buildArray += $buildNumber
    
        $tagId = $response.psobject.Properties.Value.release.artifacts.definitionReference.branch.id
        Write-Host 
        if ($tagID.count -gt 1){
          $tagId = $tagId[1]
          Write-Host ("tagId:",$tagId[1])
          $tag = $tagId.split("/")
          Write-Host ("tag of $component is:", $tag[2])
          $buildArray += $tag[2]        
        } else {
          Write-Host ("tagId:",$tagId)
          $tag = $tagId.split("/")
          Write-Host ("tag of $component is:", $tag[2])
          $buildArray += $tag[2] 
        }       
  
        Write-Host
    } else {        
        $artifactsAlias = $response.psobject.Properties.Value.release.artifacts.alias
        #Write-Host ("artifactsAlias is:", $artifactsAlias.count)
        ##Find Index of _hrx-pay-bod-processor
        $i=0
        foreach ($el in $artifactsAlias) {            
            if ($el -eq "_hrx-pay-bod-processor") 
                { 
                    Write-Host ("el", $el) 
                    break
                } 
            $i++
        }
        $buildId = $response.psobject.Properties.Value.release.artifacts.definitionReference.version.id
        Write-Host ("buildId of $component is:", $buildId[$i])
        $buildArray += $buildId[$i]
  
        $buildNumber =  $response.psobject.Properties.Value.release.artifacts.definitionReference.version.name
        Write-Host ("buildNumber of $component is:",$buildNumber[$i])
        $buildArray += $buildNumber[$i]       
  
        $tagId = $response.psobject.Properties.Value.release.artifacts.definitionReference.branch.id
        #Write-Host ("tagId:",$tagId[$i])
        $tag = $tagId[$i].split("/")
        Write-Host ("tag of $component is:", $tag[2])
        $buildArray += $tag[2]        
        
    }  
    #retruns Array [buildId , buildNumber , tag]
    #retruns Array [146630 , 20220629.7 , 23.1.2]
    return $buildArray
  }
  
  function createWorkItem {
    param (
        [string]$organizationUrl = "https://dev.azure.com/ProdNGAHR",
        [string]$projectName = "HR%20Portfolio",
        [string]$taskAreaPath = "HR Portfolio\PIP\PS",
        [string]$taskDescription = "",
        [string]$taskTitle = ""
    )

    $pat = "zjjesgh2xqpduxrdacersjtgfnemgzjrstvnkqppm23vnl6toarq" 
    $headers = @{Authorization=("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "",$pat))))}

    #Get Current Iteration
    $currentIterationUrl = "$organizationUrl/$projectName/_apis/work/teamsettings/iterations?api-version=6.0"

    $currentIterationResponse = Invoke-RestMethod -Uri $currentIterationUrl -Method GET -Headers $headers

    if ($currentIterationResponse -and $currentIterationResponse.value -and $currentIterationResponse.value.Count -gt 0) {
    $currentIteration = $currentIterationResponse.value | Where-Object { $_.attributes.timeFrame -eq "current" }

    if ($null -eq $currentIteration) {
        Write-Host "Failed to retrieve current iteration details."
        exit
    }
    $currentIterationPath = $currentIteration.path
    Write-Host "Current Iteration Path: $($currentIteration.path)"
    }
    else {
    Write-Host "Failed to retrieve iteration details. API Response:"
    $currentIterationResponse
    }

    # Convert the task details to JSON
    $payload = @(
    @{
        "op" = "add"
        "path" = "/fields/System.Title"
        "value" = "$taskTitle"
    },
    @{
        "op" = "add"
        "path" = "/fields/System.Description"
        "value" = "$taskDescription"
    },
    @{
        "op" = "add"
        "path" = "/fields/System.IterationPath"
        "value" = "$currentIterationPath"
    },
    @{
        "op" = "add"
        "path" = "/fields/System.AreaPath"
        "value" = "$taskAreaPath"
    }

    )


    $jsonPayload = $payload | ConvertTo-Json -Depth 10

    $taskUrl =  "$organizationUrl/$projectName/_apis/wit/workitems/`$Task?api-version=5.1"

    $response = Invoke-RestMethod -Uri $taskUrl -Method POST -Headers $headers -Body $jsonPayload -ContentType "application/json-patch+json"
    Write-Host "TASK URL:"$response
    if ($response.id) {
    Write-Host "Task created successfully. Task ID: $($response.id)"
    }
    else {
    Write-Host "Failed to create task. Error message: $($response.message)"

    }
}


function GetRequestedTag {
    param (
        [string]$p_varPrefix = "DEPLOY_RELEASE_",
        [string]$p_component = "calcdb",
        [boolean]$p_verbose = $true
    )
    $lv_compUpperCase = $p_component.toupper()
    $lv_variableDeployComponentVersionName = $p_varPrefix + $lv_compUpperCase
    $lv_requestedTag = [Environment]::GetEnvironmentVariable($lv_variableDeployComponentVersionName)
    if ([string]::IsNullOrEmpty($lv_requestedTag)){
        $lv_requestedTag = $env:DEPLOY_RELEASE
    }
    if ( $p_verbose -eq $true){
        Write-Host "The requestedTag for $p_component is $lv_requestedTag"
    }
    return $lv_requestedTag
}

function ValidateRequestedTagOverPreviousEnv {
    param (
        [string]$p_requestedTag = "26.2.0",
        [string]$p_previousEnvTag = "26.1.0",
        [string]$p_component = "calcdb",
        [boolean]$p_verbose = $true
    )
    Write-Host "The requestedTag: $p_requestedTag"
    Write-Host "The previousEnvTag: $p_previousEnvTag"

    if ( $p_requestedTag -eq $p_previousEnvTag){
        if ( $p_verbose -eq $true){
            Write-Host "The requestedTag is the same as deployed in previous environment for $p_component, deployment can proceed"
        }
        $lv_tagDifferent = 0
    } else {
        if ( $p_verbose -eq $true){
            Write-Warning "The requestedTag is different from the tag deployed in previous environment for $p_component"
        }
        $lv_tagDifferent = 1
    }
    return $lv_tagDifferent
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
            'TSTNF' { $lb_mappingNeeded=$true }
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
