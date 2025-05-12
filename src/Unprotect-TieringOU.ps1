<#
# Synopsis: Remove protection from accidental deletion in Tiering OUs
# Author: h4n0sh1
# License : GPL-2.0
# Created: 05/12/2025
#>

[CmdletBinding()]
param(
     [Parameter(Mandatory=$False)]
     [String]$XML_PATH = "..\data\results\Tiering-OU-populated.xml"

)

Import-Module "..\lib\modules\LibXML.psm1" -Force

[xml]$Tiering_OU = Get-Content $XML_PATH
$ROOT_NODE = $Tiering_OU.STRUCTURE.FirstChild
$BASE_DN = (Get-ADDomain).DistinguishedName

function Remove-ProtectionFromADTieringOU([System.Xml.XmlLinkedNode]$node){
    $ou_path = Get-LdapPathFromXMLNode $node "STRUCTURE"
    $parent_path = ($ou_path -split ',',2)[1]
    Get-ADOrganizationalUnit -Identity "$ou_path" | `
      Set-ADObject -ProtectedFromAccidentalDeletion:$false -PassThru
}

Write-Host -BackgroundColor Red -ForegroundColor White "Unprotecting following OUs in directory tree:"
Search-XmlAllNodes $ROOT_NODE ${function:\Remove-ProtectionFromADTieringOU}
