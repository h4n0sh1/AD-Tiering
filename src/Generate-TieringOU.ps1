<#
# Synopsis: Generate Tiering OU from XML structure
# Author: h4n0sh1
# License : GPL-2.0
# Created: 04/29/2025
#>

[CmdletBinding()]
param(
     [Parameter(Mandatory=$False)]
     [String]$XML_PATH = "..\lib\templates\Tiering-OU.xml"

)

Import-Module "..\lib\modules\LibXML.psm1" -Force

[xml]$Tiering_OU = Get-Content $XML_PATH
$ROOT_NODE = $Tiering_OU.STRUCTURE.FirstChild

function New-ADTieringOU([System.Xml.XmlLinkedNode]$node){
    $ou_path = Get-LdapPathFromXML $node "STRUCTURE"
    $parent_path = ($ou_path -split ',',2)[1]
    Write-Host $ou_path
    New-ADOrganizationalUnit -Name $node.name -Path $parent_path
}

Write-Host -BackgroundColor Yellow -ForegroundColor Black "Creating following OUs in directory tree:"
Search-XmlAllNodes $ROOT_NODE ${function:\New-ADTieringOU}

