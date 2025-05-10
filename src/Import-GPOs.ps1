<#
# Synopsis: Import GPOs from AD Tree
# Author: h4n0sh1
# License : GPL-2.0
# Created: 05/10/2025
#>

Import-Module "..\lib\modules\LibCSV.psm1" -Force

$BASE_DN = (Get-ADDomain).DistinguishedName

$GpoLinks_Path = "$PSScriptRoot\..\data\exports\GPO_Links.csv"
$GPO_Links = Import-Csv -Path $GpoLinks_Path
$GPO_map = @{}

$GPO_Links | %{
    $gpo_name = $_.DisplayName
    if($_.Target -match "(.*?),(DC=.*)"){
        $old_ldap_relative_path = $Matches[1] -replace '"'
        $Matches.Clear()
        $dc_ldap_path = $BASE_DN
        $new_ou_ldap_path = $old_ldap_relative_path + "," + $dc_ldap_path
        if($GPO_map.ContainsKey($gpo_name)){
            New-GPO -Name $gpo_name
            $GPO_map.Add($gpo_name,"")
        }
        New-GPLink -Name $gpo_name -Target $new_ou_ldap_path
    }
}

