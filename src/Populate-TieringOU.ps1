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
     [String]$AD_TREE_PATH = "..\data\exports\AD-Tree-CONFIDENTIAL.csv",
     [Parameter(Mandatory=$False)]
     [String]$XML_TEMPLATE_PATH = "..\lib\templates\Tiering-OU.xml",
     [Parameter(Mandatory=$False)]
     [String]$XML_OUTPUT_PATH = "..\data\results\Tiering-OU-populated.xml",
     [Parameter(Mandatory=$False)]
     [String]$TIERING_MAP_PATH = "..\data\results\Tiering-Map.csv"
)

Import-Module "..\lib\modules\LibXML.psm1" -Force

$AD_Tree = Import-Csv -Path $AD_TREE_PATH
$GLOBAL:CLASS_MAP = @{} 

Copy-Item $XML_TEMPLATE_PATH -Destination $XML_OUTPUT_PATH -Force
[xml]$xml = Get-Content $XML_OUTPUT_PATH
$ROOT_NODE = $xml.STRUCTURE.FirstChild


function Search-ADTreeFromCSV([System.Array]$csv,
                              [ScriptBlock]$function,
                              [xml]$xml,
                              [String]$xml_template_path = $XML_TEMPLATE_PATH,
                              [String]$xml_output_path=$XML_OUTPUT_PATH){

    $csv | %{
        if($CLASS_MAP.Keys -contains $_.ObjectClass){
            if($_.DistinguishedName -match "(.*?),DC=.*"){
                $object_path = $Matches[1]
                $Matches.Clear()
                Invoke-Command $function -ArgumentList ($object_path,$_.ObjectClass,$xml,$xml_template_path,$xml_output_path,${function:\New-XMLNodes}) 
                
            }
        }
    }
}


Search-XmlAllNodes $ROOT_NODE ${function:\Get-ClassFromNode}
Search-ADTreeFromCSV $AD_Tree ${function:\Search-XMLNodeByClass} $xml
Get-TieringMapCSV $TIERING_MAP_PATH