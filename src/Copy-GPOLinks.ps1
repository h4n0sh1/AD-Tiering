<#
# Synopsis: Copy GPO Links to new Tiering OUs
# Author: h4n0sh1
# License : GPL-2.0
# Created: 05/09/2025
#>

Import-Module "..\lib\modules\LibCSV.psm1" -Force

$BASE_DN = (Get-ADDomain).DistinguishedName

$GpoLinks_Path = "$PSScriptRoot\..\data\exports\GPO_Links.csv"
$TieringMap_Path = "$PSScriptRoot\..\data\results\Tiering-Map.csv"

$Tiering_map = Import-MapFromCsv $TieringMap_Path
$GPO_Links = Import-Csv -Path $GpoLinks_Path

$GPO_Links | %{
    $gpo_name = $_.DisplayName
    if($_.Target -match "(.*?),(DC=.*)"){
        $old_ldap_relative_path = $Matches[1]
        $dc_ldap_path = $BASE_DN
        if($Tiering_map.ContainsKey($old_ldap_relative_path)){
            $Tiering_map[$old_ldap_relative_path] -split "//" | %{
                $new_ou_ldap_path = $($_ -replace '"') + "," + $dc_ldap_path
                try{
                    New-GPLink -Name $gpo_name -Target $new_ou_ldap_path -ErrorAction Stop | Out-Null
                    Write-Host -BackgroundColor Green -ForegroundColor White "Successfully linked $gpo_name to $new_ou_ldap_path"
                }catch {
                    Write-Host -BackgroundColor Yellow -ForegroundColor Black "The GPO $gpo_name is already linked to $new_ou_ldap_path"
                }
                
            }          
        }
    }
}

