<#
# Synopsis: Module for AD operations
# Author: h4n0sh1
# License : GPL-2.0
# Created: 05/09/2025
#>

$BASE_DN = (Get-ADDomain).DistinguishedName

function New-ADOrganizationalUnitRecursive([String]$OU_PATH,
                                           [Int]$DEPTH=0,
                                           [Int]$MAX_DEPTH=100
                                           ){
    if($DEPTH -eq $MAX_DEPTH){
        Write-Host -BackgroundColor Red -ForegroundColor White "Maximum depth reached..."
        return
    }
    try{
        Get-ADOrganizationalUnit $OU_PATH | Out-Null
        Write-Host -BackgroundColor Yellow -ForegroundColor Black "The OU [$OU_PATH] already exists"     
    }catch{
        $PARENT_OU_PATH = ($OU_PATH -split ",",2)[1]
        if($PARENT_OU_PATH -match "OU=.*")
        {
            New-ADOrganizationalUnitRecursive $PARENT_OU_PATH ($DEPTH+1)
        }
        if(($OU_PATH -split ",",2)[0] -match "OU=(.*)")
        {
            $OU_NAME = $Matches[1]
            $Matches.Clear()
            if($PARENT_OU_PATH -match "$BASE_DN"){
                Write-Host -BackgroundColor Green -ForegroundColor White "Inserting new OU [$OU_PATH] ..."
                New-ADOrganizationalUnit -Name $OU_NAME -Path $PARENT_OU_PATH
            }else{
                Write-Host "Error in Domain Name."
            }
         }     
        return    
    }
}
