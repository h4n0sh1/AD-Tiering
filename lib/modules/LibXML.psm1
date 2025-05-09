<#
# Synopsis: Module for XML processing
# Author: h4n0sh1
# License : GPL-2.0
# Created: 04/29/2025
#>

$BASE_DN = (Get-ADDomain).DistinguishedName
# Key = Original OU Ldap PATH :: Object Class , Value = Array of new OUs Ldap paths
$TIERING_MAP = @{}
#$TIERING_OUTPUT_XML_PATH = "..\data\results\Tiering-OU-populated.xml"

# Returns Tiering_Map in CSV format 
function Get-TieringMapCSV([String]$csv_path,
                           [Hashtable]$tiering_map=$TIERING_MAP              
                          ){
    $csv = @()
    $tiering_map.GetEnumerator() |%{
        $OLD_OU_PATH = ($_.Key -split "::")[0]
        $OBJECT_CLASS = ($_.Key -split "::")[1]
        $NEW_OUS_PATHS = $_.Value
        $csv += [PSCustomObject][ordered]@{
            OLD_OU_PATH = $OLD_OU_PATH
            OBJECT_CLASS= $OBJECT_CLASS
            NEW_OU_PATHS = '"{0}"' -f ($NEW_OUS_PATHS -join '"//"')
        }
    }
    $csv | Sort-Object -Property "OLD_OU_PATH" | Export-Csv -Path "$csv_path" -NoTypeInformation -Encoding UTF8 -Force
}

# Get XPath from $node with regards to xml structure (xmlns inc.)
function Get-XPathFromXMLNode([System.Xml.XmlNode]$node,
                              [Int]$first_trigger=1,
                              [String]$XPath = "/"
                              ){
    if( $node.ParentNode -ne $null ){
        if($node.LocalName -eq 'OU'){
            $XPath = (Get-XPathFromXMLNode $node.ParentNode 0) + "OU[@NAME='" + $node.Name + "']/"
        }else{
            $XPath = (Get-XPathFromXMLNode $node.ParentNode 0) + $node.Name + "/"
        }    
    }
    if($first_trigger){
        $XPath = $XPath.Substring(0,$XPath.Length-1)
    }
    return $XPath 
}

function Get-XPathFromLDAP([String]$ldap_path,
                           [String]$rootNodeName,
                           [String]$XPath = "/$rootNodeName/"
                           ){
    $ldap_array = $ldap_path -split ","
    $ldap_array[-1..-($ldap_array.Length)] | %{
        $XPath += "OU[@NAME='" + (($_ -split "=")[1]) + "']/"
    }
    return $XPath.Substring(0,$XPath.Length-1)
}

# Get LDAP path of an object from it's associated XML $node
function Get-LdapPathFromXML([System.Xml.XmlLinkedNode]$node,
                             [String]$rootNodeName
                             ){  
    $XMLNodePath = ""
    while($node.LocalName -ne $rootNodeName)
    {
     $XMLNodePath += ($node.LocalName + "=" + $node.NAME + ",")
     $node = $node.ParentNode   
    }
    $XMLNodePath += $BASE_DN
    return $XMLNodePath
}

# Recursive search of all nodes starting from $node. Processing each node with $function.
function Search-XmlAllNodes([System.Xml.XmlLinkedNode]$node,
                            [ScriptBlock]$function
                            ){
    while($node -ne $null){
        Invoke-Command $function -ArgumentList $node 
        if($node.hasChildNodes){
            Search-XmlAllNodes $node.FirstChild $function
        }
        $node=$node.NextSibling
    }
}

# Search all sibling nodes from $node. Processing each node with $function.
function Search-XmlSiblingNodes([System.Xml.XmlLinkedNode]$node,
                                [ScriptBlock]$function
                                ){
        while($node -ne $null){
            Invoke-Command $function -ArgumentList $node
            $node=$node.NextSibling
        }
}

# Insert OU located in $old_ldap_path (relative to TLD) into XML file, at $node 
function New-XMLNodes([String]$old_ou_ldap_path,
                      [String]$object_class,
                      [System.Xml.XmlLinkedNode]$tiering_ou_xml_node,
                      [xml]$xml,
                      [String]$xml_path
                      ){
    $rootNodeName = $xml.FirstChild.NextSibling.LocalName

    # Loop through OUs in reverse order (from parent to child)
    $old_ou_array = ($old_ou_ldap_path -split ",")
    $previous_ou_ldap_path = ""
    $old_sub_ou_ldap_path = ""
    $old_ou_array[-1..-($old_ou_array.Length)] | %{
        $ou_name = ($_ -split "=")[1] 

        # Strips OU LDAP Path from DC
        if((Get-LdapPathFromXML $tiering_ou_xml_node $rootNodeName) -match "(.*?),DC=.*"){
            $tiering_ou_ldap_path = $Matches[1]
            $Matches.Clear()
            
            # Find XPath of parent node to insert from
            if($previous_ou_ldap_path.Length -eq 0){
                $old_sub_ou_ldap_path = "OU=" + $ou_name 
                $insert_node_xPath = Get-XPathFromXMLNode $tiering_ou_xml_node
                Write-Host "Importing OU: $insert_node_xPath"
            }else{
                $old_sub_ou_ldap_path = "OU=" + $ou_name + "," + $old_sub_ou_ldap_path
                $insert_node_xPath = Get-XPathFromLDAP $previous_ou_ldap_path $rootNodeName
                Write-Host "Importing OU: $insert_node_xPath"
            }    

            # Checks if new node to insert is already present, else append it to parent node
            $new_sub_ou_ldap_path = $old_sub_ou_ldap_path + "," + $tiering_ou_ldap_path
            $new_sub_ou_xPath = Get-XPathFromLDAP $new_sub_ou_ldap_path $rootNodeName
            if($xml.SelectSingleNode($new_sub_ou_xPath) -eq $null){
                $insert_from_xml_node = $xml.SelectSingleNode($insert_node_XPath)
                $new_xml_node = $xml.CreateElement("OU")
                $new_xml_node.setAttribute("NAME",$ou_name) | Out-Null
                $new_xml_node.setAttribute("Class",$object_class) | Out-Null
                $insert_from_xml_node.AppendChild($new_xml_node) | Out-Null
                $xml.save($xml_path)
            }

            # Updates ref. to current sub_ou path for next iteration
            $previous_ou_ldap_path = $new_sub_ou_ldap_path

            # Adds current sub_ou path to dictionary to avoid looping for already created paths in Search-XMLNodeByClass
            # A key = 'ou_path' can match to multiple new entries if it contains : different object type [OR] object class exists in different tiers
            if($TIERING_MAP.ContainsKey($old_sub_ou_ldap_path+"::$object_class")){
                $TIERING_MAP[$old_sub_ou_ldap_path+"::$object_class"] += $new_sub_ou_ldap_path
            }else{
                $TIERING_MAP.Add($old_sub_ou_ldap_path+"::$object_class",@($new_sub_ou_ldap_path)) 
            } 
        }
    }
}

# Search all nodes where attribute "Class" matches the object class. Processing each node with $function
function Search-XMLNodeByClass([String]$object_ldap_path,
                               [String]$object_class,
                               [xml]$xml,
                               [String]$xml_template_path,
                               [String]$xml_output_path,
                               [ScriptBlock]$function
                               ){
    # Strips LDAP path from CN, keep only OU paths
    if($object_ldap_path -match "CN=[^,]*,(OU=.*)"){
        $old_ou_ldap_path = $Matches[1]
        $Matches.Clear()
        
        $tiering_ou_xml_nodes = Select-Xml "//*[@Class='$($object_class)']" $xml_template_path

        if(!$TIERING_MAP.ContainsKey($old_ou_ldap_path+"::$object_class")){
            $tiering_ou_xml_nodes | %{
                Invoke-Command $function -ArgumentList $old_ou_ldap_path, $object_class, $_.Node, $xml, $xml_output_path
            }     
        } 
    }                            
}

# Adds XML node class attribute to the global class_map dict.
function Get-ClassFromNode([System.Xml.XmlNode]$node
                           ){
    $class = $node.Class
    if($class -ne $null -and !$class_map.ContainsKey($class)){
        $class_map.Add($class,"")
    }                   
}