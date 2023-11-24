<# [CmdletBinding()]

param (
    [string]$Deploy_Release="",
    [string]$Deploy_Release_CalcApi="",
    [string]$Deploy_Release_CalcDb="",
    [string]$Deploy_Release_CalcUi="",
    [string]$Deploy_Release_PayApi="",
    [string]$Deploy_Release_PayUi="",
    [string]$Deploy_Release_PayBodp=""
) #>
#Assing full release version if current component version is empty
if ([string]::IsNullOrEmpty($env:Deploy_Release_CalcApi)){
	$Deploy_Release_CalcApi = $env:Deploy_Release
} else {
    $Deploy_Release_CalcApi = $env:Deploy_Release_CalcApi
}
if ([string]::IsNullOrEmpty($env:Deploy_Release_CalcUi)){
	$Deploy_Release_CalcUi = $env:Deploy_Release
} else {
    $Deploy_Release_CalcUi = $env:Deploy_Release_CalcUi
}
if ([string]::IsNullOrEmpty($env:Deploy_Release_PayApi)){
	$Deploy_Release_PayApi = $env:Deploy_Release
} else {
    $Deploy_Release_PayApi = $env:Deploy_Release_PayApi
}
if ([string]::IsNullOrEmpty($env:Deploy_Release_PayUi)){
	$Deploy_Release_PayUi = $env:Deploy_Release
} else {
    $Deploy_Release_PayUi = $env:Deploy_Release_PayUi
}
if ([string]::IsNullOrEmpty($env:Deploy_Release_PayBodp)){
	$Deploy_Release_PayBodp = $env:Deploy_Release
} else {
    $Deploy_Release_PayBodp = $env:Deploy_Release_PayBodp
}
$pingHcFlag = 0
$components = "calcApi" , "calcUi", "calcDb", "payApi", "payUi" ,"payBodp"
$lv_releaseEnvName = $env:RELEASE_ENVIRONMENTNAME
$lv_requestedTag = $env:DEPLOY_RELEASE

$Deploy_CalcApi = $env:Deploy_CalcApi
$Deploy_CalcDb = $env:Deploy_CalcDb
$Deploy_CalcUi = $env:Deploy_CalcUi
$Deploy_PayApi = $env:Deploy_PayApi
$Deploy_PayBodp = $env:Deploy_PayBodp
$Deploy_PayUi = $env:Deploy_PayUi

# Load the shared lib
$scriptPath = $MyInvocation.MyCommand.Path 
$scriptFolder = Split-Path $scriptPath -Parent
$LibFolder = Split-Path $scriptFolder -Parent
. "$LibFolder\99-functionLib"

$isClientControlledEnv='N'
if ($envArray -match $lv_releaseEnvName.tolower()){
    #For 'onb','qas','prd','qa2','onbnf'
    $isClientControlledEnv='Y'
    $lv_releasePrevEnvName = GetPreviousEnvironment $lv_releaseEnvName
}

Foreach ($lv_component in $components) { 
    Write-Host ("-----------------------------------------------------------")
    if ( $lv_component -eq "calcDb"){
        Write-Host "Not checking Ping for CalcDB"
        continue
    }

    $lv_compUpperCase = $lv_component.toupper()
    $lv_url = GetPingUrl $lv_releaseEnvName $lv_component
    
    if (![string]::IsNullOrEmpty($lv_url)){
        $lv_pingUrlVar = $lv_component + "_PING_URL"
        #DefineAsEnvVar $lv_pingUrlVar $lv_url $VariableFile
        Write-Host "the ping url for $lv_component in $lv_releaseEnvName is $lv_url"
        # GetCurrentTag
        $lv_CurrentTag = GetVersionFromPingUrl $lv_url $lv_component $lv_releaseEnvName
        if (![string]::IsNullOrEmpty($lv_CurrentTag)){
            $lv_CurrentTagVar = $lv_component + "_TAG_CURRENT"
            #DefineAsEnvVar $lv_CurrentTagVar $lv_CurrentTag $VariableFile
            Write-Host "the current tag/version for $lv_component in $lv_releaseEnvName is $lv_CurrentTag"

        switch ($lv_component) {
            "calcApi"  { 
                if ($Deploy_CalcApi.toUpper() -eq 'Y'){
                    if ($isClientControlledEnv -eq 'Y'){
                        $lv_url = GetPingUrl $lv_releasePrevEnvName $lv_component
                        $lv_PrevEnvtag = GetVersionFromPingUrl $lv_url $lv_component $lv_releasePrevEnvName    
                        if ( $lv_PrevEnvtag -eq $lv_CurrentTag) {
                            Write-Host "the version for $lv_component is same as deployed"  
                            Write-Host "Deploy_Release_CalcApi:$lv_PrevEnvtag"                     
                        } else {
                            Write-Host "Error:the version for $lv_component is NOT same as deployed" 
                            Write-Host "Deploy_Release_CalcApi:$lv_PrevEnvtag"
                            $pingHcFlag = 1                        
                        }
                    } else {
                        if ( $lv_CurrentTag -eq $Deploy_Release_CalcApi) {
                            Write-Host "the version for $lv_component is same as deployed"  
                            Write-Host "Deploy_Release_CalcApi:$Deploy_Release_CalcApi"
                        } else {
                            Write-Host "Error:the version for $lv_component is NOT same as deployed" 
                            Write-Host "Deploy_Release_CalcApi:$Deploy_Release_CalcApi"
                            $pingHcFlag = 1
                        }
                    }                
                }
            }
            "calcUi"  { 
                if ($Deploy_CalcUi.toUpper() -eq 'Y'){
                    if ($isClientControlledEnv -eq 'Y'){
                        $lv_url = GetPingUrl $lv_releasePrevEnvName $lv_component
                        $lv_PrevEnvtag = GetVersionFromPingUrl $lv_url $lv_component $lv_releasePrevEnvName    
                        if ( $lv_PrevEnvtag -eq $lv_CurrentTag) {
                            Write-Host "the version for $lv_component is same as deployed"  
                            Write-Host "Deploy_Release_CalcApi:$lv_PrevEnvtag"                     
                        } else {
                            Write-Host "Error:the version for $lv_component is NOT same as deployed" 
                            Write-Host "Deploy_Release_CalcApi:$lv_PrevEnvtag"
                            $pingHcFlag = 1                        
                        }
                    } else {
                        if ( $lv_CurrentTag -eq $Deploy_Release_CalcUi) {
                            Write-Host "the version for $lv_component is same as deployed"  
                            Write-Host "Deploy_Release_CalcUi:$Deploy_Release_CalcUi"
                        } else {
                            Write-Host "Error:the version for $lv_component is NOT same as deployed"  
                            Write-Host "Deploy_Release_CalcUi:$Deploy_Release_CalcUi"
                            $pingHcFlag = 1
                        }
                    }
                }
            }
            "payApi"  {  
                if ($Deploy_PayApi.toUpper() -eq 'Y'){
                    if ($isClientControlledEnv -eq 'Y'){
                        $lv_url = GetPingUrl $lv_releasePrevEnvName $lv_component
                        $lv_PrevEnvtag = GetVersionFromPingUrl $lv_url $lv_component $lv_releasePrevEnvName    
                        if ( $lv_PrevEnvtag -eq $lv_CurrentTag) {
                            Write-Host "the version for $lv_component is same as deployed"  
                            Write-Host "Deploy_Release_CalcApi:$lv_PrevEnvtag"                     
                        } else {
                            Write-Host "Error:the version for $lv_component is NOT same as deployed" 
                            Write-Host "Deploy_Release_CalcApi:$lv_PrevEnvtag"
                            $pingHcFlag = 1                        
                        }
                    } else {
                        if ( $lv_CurrentTag -eq $Deploy_Release_PayApi) {
                            Write-Host "the version for $lv_component is same as deployed"  
                            Write-Host "Deploy_Release_PayApi:$Deploy_Release_PayApi"
                        } else {
                            Write-Host "Error:the version for $lv_component is NOT same as deployed"  
                            Write-Host "Deploy_Release_PayApi:$Deploy_Release_PayApi"
                            $pingHcFlag = 1
                        }
                    }
                }         
            }
            "payUi"   { 
                if ($Deploy_PayUi.toUpper() -eq 'Y'){
                    if ($isClientControlledEnv -eq 'Y'){
                        $lv_url = GetPingUrl $lv_releasePrevEnvName $lv_component
                        $lv_PrevEnvtag = GetVersionFromPingUrl $lv_url $lv_component $lv_releasePrevEnvName    
                        if ( $lv_PrevEnvtag -eq $lv_CurrentTag) {
                            Write-Host "the version for $lv_component is same as deployed"  
                            Write-Host "Deploy_Release_CalcApi:$lv_PrevEnvtag"                     
                        } else {
                            Write-Host "Error:the version for $lv_component is NOT same as deployed" 
                            Write-Host "Deploy_Release_CalcApi:$lv_PrevEnvtag"
                            $pingHcFlag = 1                        
                        }

                    } else {
                        if ( $lv_CurrentTag -eq $Deploy_Release_PayUi) {
                            Write-Host "the version for $lv_component is same as deployed"  
                            Write-Host "Deploy_Release_PayUi:$Deploy_Release_PayUi"
                        } else {
                            Write-Host "Error:the version for $lv_component is NOT same as deployed" 
                            Write-Host "Deploy_Release_PayUi:$Deploy_Release_PayUi" 
                            $pingHcFlag = 1
                        }
                    }
                }                
            }
            Default {}
            }

        } else {
            Write-Host "Not able to get the CurrentTag/CurrentVersion for $lv_component in $lv_releaseEnvName"

        }
    } else {
        Write-Host "Error: Not able to get the pingUrl for $lv_component in $lv_releaseEnvName"
        if ($Deploy_PayBodp.toUpper() -eq 'Y'){
            if ( $lv_component -eq "payBodp"){
                $lv_releaseEnvName_lower=$lv_releaseEnvName.tolower()
                Write-Host "lv_releaseEnvName_lower = $lv_releaseEnvName_lower"
                try {
                    if ($isClientControlledEnv -eq 'Y'){
                        Write-Host "Skipping payBodp health check"
<#                         $lv_releasePrevEnvName_lower = $lv_releasePrevEnvName.toLower()
                        kubectlSetNamespace -p_env $lv_releasePrevEnvName_lower
                        $lv_PrevEnvtag = kubectlGetInfo -p_deployment "hrx-pay-bod-processor" -p_information "image"
                        Write-Host "lv_PrevEnvtag:$lv_PrevEnvtag"

                        kubectlSetNamespace -p_env $lv_releaseEnvName_lower
                        $lv_tag_PayBodp = kubectlGetInfo -p_deployment "hrx-pay-bod-processor" -p_information "image"
                        if ( $lv_tag_PayBodp -eq $lv_PrevEnvtag) {
                            Write-Host "the version for $lv_component is same as deployed"  
                            Write-Host "Deploy_Release_PayBodp:$lv_tag_PayBodp"
                        }  else {
                            Write-Host "Error:the version for $lv_component is NOT same as deployed" 
                            Write-Host "Deploy_Release_PayBodp:$lv_tag_PayBodp" 
                            $pingHcFlag = 1
                        }     #>     
                    } else {
                        kubectlSetNamespace -p_env $lv_releaseEnvName_lower
                        $lv_tag_PayBodp = kubectlGetInfo -p_deployment "hrx-pay-bod-processor" -p_information "image"
                        Write-Host "lv_tag_PayBodp:$lv_tag_PayBodp"
                        if ( $lv_tag_PayBodp -eq $Deploy_Release_PayBodp) {
                            Write-Host "the version for $lv_component is same as deployed"  
                            Write-Host "Deploy_Release_PayBodp:$Deploy_Release_PayBodp"
                        } else {
                            Write-Host "Error:the version for $lv_component is NOT same as deployed" 
                            Write-Host "Deploy_Release_PayBodp:$Deploy_Release_PayBodp" 
                            $pingHcFlag = 1
                        }                        
                    }              
                } catch {
                    Write-Host $_
                    Write-Host "Not able to check the version using kubectl"
                }
            }
        }
    }
}
if ($pingHcFlag -eq 1){
    Write-Host "Ping version check has been failed. check above Log of Error" 
    exit 1
}
