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
$CLASSES_TO_REPLICATE = @("organizationalUnit",
                          "user",
                          "group",
                          "msDS-GroupManagedServiceAccount"
                          )

function Search-ADTreeFromCSV([System.Array]$csv
                              ){

    $csv | %{
        if(
           $CLASSES_TO_REPLICATE.Keys -contains $_.ObjectClass -and 
           $_.DistinguishedName -match "(.*?),DC=.*"
           ){
            $object_path = $Matches[1]
            $Matches.Clear()
            switch($_.ObjectClass)
            {
                "organizationalUnit"
                { 
                  
                }
                "user"
                {

                }
                "group"
                {

                }
                "msDS-GroupManagedServiceAccount"
                {

                }

            }

        }
    }
}

New-ADOrganizationalUnitRecursive "OU=GROUPEX,OU=AVD,DC=h4n0sh1,DC=org"