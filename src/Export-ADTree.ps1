<#
# Synopsis: Extract OUs, Containers, Objects and other built-ins to replicate.
# Author: h4n0sh1
# License : GPL-2.0
# Created: 04/24/2025
#>

$EXPORT_PATH = "$PSScriptRoot\..\data\exports\AD-Tree.csv"
#List of AD tree containers and OUs  
$ad_tree = @()


#Simple tree search - excludes other 
Get-ADObject -LDAPFilter '((objectclass=*))' -Properties CanonicalName | %{
    $cn_identifier = "null"

    #Strips CN from domain name
    if($_.CanonicalName -match "\w*\/(.*)"){
        $cn_identifier = $Matches[1]
        $Matches.Clear()
    }

    $ad_tree += [PSCustomObject][ordered]@{
        cn_identifier = $cn_identifier
        CanonicalName = $_.CanonicalName
        DistinguishedName = $_.DistinguishedName
        ObjectClass = $_.ObjectClass
    }
     
}

#Export AD tree in the same order it appears on dsa.msc
$ad_tree | Sort-Object -Property "cn_identifier" | Export-Csv -Path $EXPORT_PATH -NoTypeInformation -Encoding UTF8 -Force
