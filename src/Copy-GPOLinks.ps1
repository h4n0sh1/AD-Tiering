<#
# Synopsis: Copy GPO Links to new Tiering OUs
# Author: h4n0sh1
# License : GPL-2.0
# Created: 05/09/2025
#>

Import-Module "..\lib\modules\LibCSV.psm1" -Force

$GpoLinks_Path = "$PSScriptRoot\..\data\exports\GPO_Links.csv"
$TieringMap_Path = "$PSScriptRoot\..\data\results\Tiering-Map.csv"

$Tiering_map = Load-MapFromCsv $TieringMap_Path
$GPO_Links = Import-Csv -Path $GpoLinks_Path

$GPO_Links | %{
    $guid = $_.GPOId
    if($_.Target -match "(.*?),(DC=.*)"){
        $old_ldap_relative_path = $Matches[1]
        $dc_ldap_path = $Matches[2]
        if($Tiering_map.ContainsKey($old_ldap_relative_path)){
            $Tiering_map[$old_ldap_relative_path]
        }
    }

}

