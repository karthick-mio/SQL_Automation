$VariableFile = $env:PREP_VariableFile

$lv_noReadyTagTST = 0
$lv_noReadyTagONB = 1
$lv_noReadyTagQAS = 1
$lv_noReadyTagPRD = 1

# Load the shared lib
$scriptPath = $MyInvocation.MyCommand.Path 
$scriptFolder = Split-Path $scriptPath -Parent
$LibFolder = Split-Path $scriptFolder -Parent
. "$LibFolder\99-functionLib"

if ([string]::IsNullOrEmpty($env:DEPLOY_RELEASE)){
    SetLocalDefaultReleasesToDeploy
}

$lv_Exit_Tag = 0
$lv_Exit_rcTag = 0
$lv_Exit_noReadyTagFoundForBuild = 0

$lv_releaseEnvName_Upper = $lv_releaseEnvName.toUpper()
if ( $lv_releaseEnvName_Upper -eq "TSTNF" -or $lv_releaseEnvName_Upper -eq "PRD"){
    $lv_workBench_Flag = 'Y'
} else {
    $lv_workBench_Flag = 'N'
}
$components = "CalcDb" , "CalcApi", "CalcUi", "PayApi", "PayUI" ,"PayBodp"
if ( $lv_workBench_Flag -eq 'Y'){
    $components = "CalcDb" , "CalcApi", "CalcUi", "PayApi", "PayUI" ,"PayBodp" ,"CalcWorkbench"
}

Foreach ($lv_component in $components) { 
    $lv_Exit_NoBuildNumberFoundForTag = 0
    $lv_componentUpper = $lv_component.toUpper()
    $tag = [Environment]::GetEnvironmentVariable("DEPLOY_RELEASE_$lv_componentUpper")
    if ([string]::IsNullOrEmpty($tag)){
        $tag = $env:DEPLOY_RELEASE
        $exit_code = checkRCtag $tag $lv_releaseEnvName
    }
    $exit_code = checkRCtag $tag $lv_releaseEnvName
    if ( $exit_code -eq 'Y'){
        Write-Host ("****ERROR:tag $tag contains aphabets in $lv_component of $env");  
        #exit
        $lv_Exit_rcTag = 1
    }

    #Write-Host "component:$lv_component - tag: $tag"
    $lv_definition  = GetBuildDefinition $lv_component
    Write-Host "lv_definition:$lv_definition"
    $buildnumber    = GetBuildNumbersForTag $tag $lv_component $lv_definition
    Write-Host "buildnumber:$buildnumber"
    if ([string]::IsNullOrEmpty($buildnumber)){
        Write-Host ("No BuildNumber found for the $tag for the $lv_component")
        $lv_Exit_NoBuildNumberFoundForTag = 1
        #exit 80
    }
    Write-Host "lv_Exit_NoBuildNumberFoundForTag:$lv_Exit_NoBuildNumberFoundForTag"
    if ( $lv_Exit_NoBuildNumberFoundForTag -eq 0 ){
        $lv_compUpperCase = $lv_component.toupper()
        $lv_var_RequestTag = $lv_compUpperCase + "_RequestTag"
        $lv_var_buildID = $lv_compUpperCase + "_buildID"
        $lv_var_buildID_Full = "PREP_" + $lv_var_buildID
        $lv_var_buildNumber = $lv_compUpperCase + "_buildNumber"
        $lv_var_buildNumber_Full = "PREP_" + $lv_var_buildNumber
        $buildid = GetBuildIdForTag $tag $lv_component $lv_definition
        
        ##Logic to find BuildTags for the specific buildID in TSTM,ONB,QAS & PRD
        switch ($lv_env_to_validate.tolower()) {
            tstm { 
                $buildTag = "readytstm" 
                $buildTagStatus = GetTagStatusForBuildId -component $lv_component -BuildId $buildid -checktag $buildTag
                if ( $buildTagStatus -eq 'Y'){
                    Write-Host "Tag $buildTag exists for the build number $buildnumber of $lv_component"
                } else {
                    Write-Host "ERROR: Tag $buildTag not exists for the build number $buildnumber of $lv_component"
                    $lv_Exit_noReadyTagFoundForBuild = $lv_noReadyTagTST
                    #exit 81
                }
            }
            onb { 
                $buildTag = "readyonb" 
                $buildTagStatus = GetTagStatusForBuildId -component $lv_component -BuildId $buildid -checktag $buildTag
                if ( $buildTagStatus -eq 'Y'){
                    Write-Host "Tag $buildTag exists for the build number $buildnumber of $lv_component"
                } else {
                    Write-Host "ERROR: Tag $buildTag not exists for the build number $buildnumber of $lv_component"
                    $lv_Exit_noReadyTagFoundForBuild = $lv_noReadyTagONB
                    #exit 81
                }
            }
            qas { 
                $buildTag = "readyqas" 
                $buildTagStatus = GetTagStatusForBuildId -component $lv_component -BuildId $buildid -checktag $buildTag
                if ( $buildTagStatus -eq 'Y'){
                    Write-Host "Tag $buildTag exists for the build number $buildnumber of $lv_component"
                } else {
                    Write-Host "ERROR: Tag $buildTag not exists for the build number $buildnumber of $lv_component"
                    $lv_Exit_noReadyTagFoundForBuild = $lv_noReadyTagQAS
                    #exit 81
                    Write-Host "For Now Allow for QAS , as no testcases run for ONB"
                }
            }
            prd { 
                $buildTag = "readyprd" 
                $buildTagStatus = GetTagStatusForBuildId -component $lv_component -BuildId $buildid -checktag $buildTag
                if ( $buildTagStatus -eq 'Y'){
                    Write-Host "Tag $buildTag exists for the build number $buildnumber of $lv_component"
                } else {
                    Write-Host "ERROR: Tag $buildTag not exists for the build number $buildnumber of $lv_component"
                    $lv_Exit_noReadyTagFoundForBuild = $lv_noReadyTagPRD
                    #exit 81
                }
            }
            Default { write-Host "BuildTag is applicable for tstm,onb,qas and prd environment only. Current environment is $lv_env_to_validate"; }
        }

        $lv_Exit_Tag = $lv_Exit_rcTag + $lv_Exit_noReadyTagFoundForBuild + $lv_Exit_NoBuildNumberFoundForTag
        Write-Host "lv_Exit_Tag:$lv_Exit_Tag"
        if ( $lv_Exit_Tag -eq 0 ) {
            DefineAsEnvVar $lv_var_RequestTag $tag $VariableFile
            DefineAsEnvVar $lv_var_buildID $buildnumber $VariableFile
            DefineAsEnvVar $lv_var_buildNumber $buildid $VariableFile
            $lv_searchBuildID = $true
            if (![string]::IsNullOrEmpty($buildnumber)){
                Write-Host "The buildNumber for $lv_component and $tag is $buildnumber"
                #Write-Host "Please Use the variable" + $lv_var_buildID_Full " as buildID in the deploy extension"
                $lv_searchBuildID = $true
            } else {
                $lv_varEnv = "DEPLOY_" + $lv_component
                DefineAsEnvVar $lv_varEnv 'N' $VariableFile
                Write-Warning "there is no build $tag for component $lv_component"
                $lv_searchBuildID = $false
            }
            if ( $lv_searchBuildID -eq $true){
                if (![string]::IsNullOrEmpty($buildid)){
                    Write-Host "The buildID for $lv_component and $tag is $buildid"
                    Write-Host "Please Use the variable $lv_var_buildNumber_Full as buildNumber in the deploy extension"
                } else {
                    $lv_varEnv = "DEPLOY_" + $lv_component
                    DefineAsEnvVar $lv_varEnv 'N' $VariableFile
                    Write-Warning "there is no build $tag for component $lv_component"
                }
            }
        } else {
            Write-Host "There was at least one Error (lv_Exit_Tag: $lv_Exit_Tag)"
        }
    }
    Write-Host "------------------------------------------------------------"
}
