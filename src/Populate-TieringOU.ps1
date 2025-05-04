<#
# Synopsis: Replicate AD Tree hierarchy into Tiering OUs w/ regards to Object Type (Users/Computers/Service accounts ...) 
#           Returns an XML that can be ingested by Generate-TieringOU
# Author: h4n0sh1
# License : GPL-2.0
# Created: 04/29/2025
#>

[CmdletBinding()]
param(
     [Parameter(Mandatory=$False)]
     [String]$CSV_PATH = "..\data\AD-Tree-CONFIDENTIAL.csv",
     [Parameter(Mandatory=$False)]
     [String]$XML_PATH = "..\lib\templates\Tiering-OU.xml"
)

Import-Module "..\lib\modules\LibXML.psm1" -Force

$AD_Tree = Import-Csv -Path $CSV_PATH
$NEW_XML_PATH = "..\lib\templates\Tiering-OU-populated.xml"


function Search-ADTreeFromCSV([System.Array]$csv,
                              [ScriptBlock]$function){
    Copy-Item $XML_PATH -Destination $NEW_XML_PATH -Force
    [xml]$xml = Get-Content $NEW_XML_PATH
    $csv | %{
        if($ANALYSED_OBJECT_TYPES -contains $_.ObjectClass){
            if($_.DistinguishedName -match "(.*?),DC=.*"){
                $object_path = $Matches[1]
                $Matches.Clear()
                Invoke-Command $function -ArgumentList ($object_path,$_.ObjectClass,$xml,${function:\New-XMLNodes}) 
                
            }
        }
    }
}

Search-ADTreeFromCSV $AD_Tree ${function:\Search-XMLNodeByClass}
Get-TieringMapCSV "..\data\Tiering-Map.csv"