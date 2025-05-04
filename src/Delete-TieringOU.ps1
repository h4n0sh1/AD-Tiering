<#
# Synopsis: Delete Tiering OU from XML structure
# Author: h4n0sh1
# License : GPL-2.0
# Created: 04/29/2025
#>

[CmdletBinding()]
param(
     [Parameter(Mandatory=$False)]
     [String]$XML_PATH = "..\lib\templates\Tiering-OU-populated.xml"

)

Import-Module "..\lib\modules\LibXML.psm1" -Force

[xml]$Tiering_OU = Get-Content $XML_PATH
$ROOT_NODE = $Tiering_OU.STRUCTURE.FirstChild
$BASE_DN = (Get-ADDomain).DistinguishedName

function Remove-ProtectionFromADTieringOU([System.Xml.XmlLinkedNode]$node){
    $ou_path = Get-LdapPathFromXML $node "STRUCTURE"
    $parent_path = ($ou_path -split ',',2)[1]
    Get-ADOrganizationalUnit -Identity "$ou_path" | `
      Set-ADObject -ProtectedFromAccidentalDeletion:$false -PassThru
}

function Delete-ADTieringOU([System.Xml.XmlLinkedNode]$node){
    $ou_path = Get-LdapPathFromXML $node "STRUCTURE"
    $parent_path = ($ou_path -split ',',2)[1]
    Remove-ADOrganizationalUnit -Identity "$ou_path" -Recursive -Confirm:$false
}

Write-Host -BackgroundColor Red -ForegroundColor White "Deleting following OUs from directory tree:"
Search-XmlAllNodes $ROOT_NODE ${function:\Remove-ProtectionFromADTieringOU}
Search-XmlSiblingNodes $ROOT_NODE ${function:\Delete-ADTieringOU}
