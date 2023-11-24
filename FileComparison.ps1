[CmdletBinding()]
param (
    [string]$gcc = "ZZA",
    [string]$lcc = "TO001",
    [string]$smtpServer = "alightsmtprelay.alight.com",
    [string]$recipient = "karthick.dillibabu@alight.com",
    [string]$subject = "Country Var Comparison difference detected - Environment",
    [string]$p_version = "0",
    [boolean]$p_local = $True,
    [boolean]$p_verbose = $True,
    [string]$p_payGroupCode = 'MT',
    [string]$diff_exit = 'Y',
    [string]$nofile_exit= 'N',
    [string]$Glrep_link = "https://prodngahr.visualstudio.com/HR%20Portfolio/_git/backbone_bundlePipeline?path=/PayCalc/Glrep",
    [string]$Var_link = "https://prodngahr.visualstudio.com/HR%20Portfolio/_git/backbone_bundlePipeline?path=/PayCalc/VarComparison",
    [string]$p_country = 'TP'
)

# Load the shared lib
$scriptPath = $MyInvocation.MyCommand.Path
$scriptFolder2 = Split-Path $scriptPath -Parent
$scriptFolder1 = Split-Path $scriptFolder2 -Parent
$scriptFolder = Split-Path $scriptFolder1 -Parent
. "$scriptFolder\99-functionLib"

$lv_releaseEnvName = $env:RELEASE_ENVIRONMENTNAME
if ( [string]::IsNullOrEmpty($lv_releaseEnvName)) {
    $lv_releaseEnvName = 'QAS-POST'
}



switch ($p_version) {
    '0' { $lv_subfolderReport = "$p_payGroupCode" }
    '1' { $lv_subfolderReport = "$p_payGroupCode" + "-var1" }
    '2' { $lv_subfolderReport = "$p_payGroupCode" + "-var2" }
    Default { $lv_subfolderReport = "$p_payGroupCode" }
}

if ( $p_version -eq 0 ) {
    $GlrepFileFolder = DefineGlrepFileFolder -scriptFolder $scriptFolder -lv_releaseEnvName $lv_releaseEnvName 
    $GlrepFileFolderPre = $GlrepFileFolder.replace("POST", "PRE")
    $GlrepFileFolderPost = $GlrepFileFolder.replace("PRE", "POST")

    $FileFolderPre = "$GlrepFileFolderPre\$lv_subfolderReport\$p_country"
    $FileFolderPost = "$GlrepFileFolderPost\$lv_subfolderReport\$p_country"

    $subject = $subject.replace("Var", "GLREP")

    $link_to_repo_post = "$Glrep_link/$($env:RELEASE_ENVIRONMENTNAME)/$p_payGroupCode/$p_country"

    $link_to_repo_pre = $link_to_repo_post.Replace("POST","PRE")


}

if ( ( $p_version -eq 1 ) -or ( $p_version -eq 2 )) {
    $VarFileFolder = DefineVarFileFolder -scriptFolder $scriptFolder -lv_releaseEnvName $lv_releaseEnvName 
    $VarFileFolderPre = $VarFileFolder.replace("POST", "PRE")
    $VarFileFolderPost = $VarFileFolder.replace("PRE", "POST")

    $FileFolderPre = "$VarFileFolderPre\$lv_subfolderReport\$p_country"
    $FileFolderPost = "$VarFileFolderPost\$lv_subfolderReport\$p_country"

    $link_to_repo_post = "$Var_link/$($env:RELEASE_ENVIRONMENTNAME)/$lv_subfolderReport/$p_country"

    $link_to_repo_pre = $link_to_repo_post.Replace("POST","PRE")
}

Write-Host "Display content of $FileFolderPre"
Get-ChildItem -Path $FileFolderPre
Write-Host "Display content of $FileFolderPost"
Get-ChildItem -Path $FileFolderPost

if ( [string]::IsNullOrEmpty($p_version)) {
    $p_version = '1'
}

switch ($p_version) {
    '0' { $lv_startFile = "GLREP_" }
    '1' { $lv_startFile = "CONTROL_" }
    '2' { $lv_startFile = "CONTROL_" }
    #Default { $lv_suffix = 'O997'; $lv_startFile = "CONTROL_" }
}


if ( [string]::IsNullOrEmpty($p_payGroupCode)) {
    $lv_Startnaming = $lv_startFile + $gcc + '_' + $lcc + '_'
}
else {
    $lv_Startnaming = $lv_startFile + $gcc + '_' + $lcc + '_' + $p_payGroupCode 
}

$lv_Endnaming = ".csv"
Write-Host "lv_Startnaming: $lv_Startnaming"
Write-Host "lv_Endnaming: $lv_Endnaming"

$lv_file = (Get-ChildItem $FileFolderPre -Filter "*.csv" | Where-Object { $_.Name -cmatch $lv_Startnaming -and $_.Name -cmatch $lv_Endnaming }).Name
$Post_lv_file = (Get-ChildItem $FileFolderPost -Filter "*.csv" | Where-Object { $_.Name -cmatch $lv_Startnaming -and $_.Name -cmatch $lv_Endnaming }).Name

if ( ! [string]::IsNullOrEmpty($lv_file)) {

    $filePre = "$FileFolderPre\$lv_file"
    $filePost = "$FileFolderPost\$Post_lv_file"

    if ( $p_verbose -eq $true ) {
        Write-Host "Files:"
        $lv_file
        $filePre
        $filePost
    }

    $FileDiff = Compare-Object -ReferenceObject $(Get-Content $filePre) -DifferenceObject $(Get-Content $filePost)
    Write-Host "=> entry only in PreFile"
    Write-Host "<= entry only in PostFile"

    if ( $FileDiff -eq $null ) {
        Write-Host "There is no difference"
        $diff_exit = 'N'
        echo "##vso[task.setvariable variable=diffFound_$p_payGroupCode]$diff_exit"
    
    }
    else {
        $diff_exit = 'Y'
        echo "##vso[task.setvariable variable=diffFound_$p_payGroupCode]$diff_exit"
        $lines = ""
        $linesPostFile = ""
        $linesPreFile = ""
        foreach ($line in $FileDiff) {
            Write-Host $line
            $lines += $line.InputObject + "|" + $line.SideIndicator + "| <br>"
            if ($line -like "*<=*") {
                # < =
                $linesPostFile += $line.InputObject + "<br>"
            }
            if ($line -like "*=>*") {
                # > =
                $linesPreFile += $line.InputObject + "<br>"
            }
        }
        Write-Host $lines
        Write-Host "--------"
        Write-Host "lines only in PreFiles"
        Write-Host $linesPreFile
        Write-Host "--------"
        Write-Host "lines only in PostFiles"
        Write-Host $linesPostFile
        Write-Host "--------"
        Write-Host "there are some differences"
        $EmailBody = Get-Content $scriptFolder2/index.html
        $EmailBody = $EmailBody -replace 'toReplaceFileName', $lv_file
        $EmailBody = $EmailBody -replace 'ToReplaceDifferencesFoundBefore', $linesPostFile
        $EmailBody = $EmailBody -replace 'ToReplaceDifferencesFoundAfter', $linesPreFile
        #Write-Host "$EmailBody"
        $EmailBody = $EmailBody -replace 'ToReplaceLinkFoundPre', $link_to_repo_pre
        $EmailBody = $EmailBody -replace 'ToReplaceLinkFoundPost', $link_to_repo_Post
        $lv_emailBody = $EmailBody | Out-String

        Write-Host "$lv_emailBody"

        $lv_env = $env:RELEASE_ENVIRONMENTNAME -replace '-POST',''

        $subject = $subject -replace 'Country', $p_country
        $subject = $subject -replace 'Environment', $lv_env

     
        switch ($p_version) {
            '0' { $subject = $subject.replace("Var", "GLREP") }
            '1' { $subject = $subject.replace("Var", "VAR PAYROLL ACCOUNT") }
            '2' { $subject = $subject.replace("Var", "VAR PAYROLL ACCOUNT GROUP") }
        }
       
        try {
            if ( $p_local -eq $false) {
                #only send email if not local
                Send-MailMessage -SmtpServer $smtpServer -From "karthick.dillibabu@alight.com" -To $recipient -Priority "High" -Subject $subject -Body $lv_emailBody -BodyAsHtml
            
                createWorkItem -taskTitle $subject -taskDescription $EmailBody}
        }
        catch {
            Write-Host $_
            Write-Host "There was an error sending email"
        }  
        echo "##vso[task.setvariable variable=diffFound_$p_payGroupCode]$diff_exit"
        echo "##vso[task.setvariable variable=FileError_$p_payGroupCode]$nofile_exit"
        exit 1

    }
    echo "##vso[task.setvariable variable=diffFound_$p_payGroupCode]$diff_exit"
    echo "##vso[task.setvariable variable=FileError_$p_payGroupCode]$nofile_exit"
}
else {
    Write-Host "File not found !"
    $nofile_exit ='y'
    echo "##vso[task.setvariable variable=FileError_$p_payGroupCode]$nofile_exit"
    exit 3
}
