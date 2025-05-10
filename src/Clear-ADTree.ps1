<#
# Synopsis: Replicate OUs, users, groups and other objects from AD Tree
# Author: h4n0sh1
# License : GPL-2.0
# Created: 04/29/2025
#>

[CmdletBinding()]
param(
     [Parameter(Mandatory=$False)]
     [String]$AD_TREE_PATH = "..\data\exports\AD-Tree-CONFIDENTIAL.csv"
)

Import-Module "..\lib\modules\LibAD.psm1" -Force

$AD_Tree = Import-Csv -Path $AD_TREE_PATH
$BASE_DN = (Get-ADDomain).DistinguishedName
$CLASSES_TO_REPLICATE = @("organizationalUnit",
                          "user",
                          "group",
                          "msDS-GroupManagedServiceAccount"
                          )

function Search-ADTreeFromCSV([System.Array]$csv
                              ){

    $csv | %{
        if(
           $CLASSES_TO_REPLICATE -contains $_.ObjectClass -and 
           $_.DistinguishedName -match "(.*?),DC=.*"
           ){
            $new_object_path = $Matches[1] + ",$BASE_DN"
            $Matches.Clear()
            switch($_.ObjectClass)
            {
                organizationalUnit
                { 
                    #Remove-ADOrganizationalUnitRecursive $new_object_path
                }
                user
                {
                    #Remove-ADUserSilently $new_object_path 
                }
                computer
                {
                    #Remove-ADComputerSilently $new_object_path
                }
                group
                {
                    #Remove-ADGroupSilently $new_object_path
                }
                msDS-GroupManagedServiceAccount
                {
                    #Remove-ADServiceSilently $new_object_path
                }

            }

        }
    }
}

Search-ADTreeFromCSV $AD_TREE