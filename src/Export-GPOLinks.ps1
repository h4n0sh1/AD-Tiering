<#
# Synopsis: Export GPO Links from AD Tree
# Author: h4n0sh1
# License : GPL-2.0
# Created: 05/09/2025
#>

$EXPORT_PATH = "$PSScriptRoot\..\data\exports\GPO_Links.csv"

try{
    $gpos = Get-ADOrganizationalUnit -Filter * | Get-GPInheritance | Select-Object -ExpandProperty GpoLinks
    $gpos | Export-Csv -Path $EXPORT_PATH -NoTypeInformation
    Write-Host -BackgroundColor Green -ForegroundColor White "Successfully exported GPO Links !"
}catch{
    Write-Host -BackgroundColor Red -ForegroundColor Black "Failed to export GPO Links ..."
    $_.ScriptStackTrace
    $_.Exception
    $_.ErrorDetails
}
