<#
# Synopsis: Module for XML processing
# Author: h4n0sh1
# License : GPL-2.0
# Created: 04/29/2025
#>

$BASE_DN = (Get-ADDomain).DistinguishedName
# Key = Original OU_PATH ; Value = New XML Node paths
$TIERING_MAP = @{}

function Get-XPath([System.Xml.XmlNode]$node,
                   [String]$XPath = "/"
                   ){
    if( $node.ParentNode -ne $null ){
        if($node.LocalName -eq 'OU'){
            $XPath = (Get-XPath $node.ParentNode) + "OU[@NAME='" + $node.Name + "']/"
        }else{
            $XPath = (Get-XPath $node.ParentNode) + $node.Name + "/"
        }    
    }
    return $XPath 
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
        #Node logic - How to handle each OU
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

# Insert OU located in $ou_path (LDAP path relative to TLD // stripped from DC) in XML file, at $node 
function New-XMLNodes([String]$ou_path,
                     [System.Xml.XmlLinkedNode]$node,
                     [String]$xml_path
                     ){
    #Loop through OUs in reverse order (from parent to child)
    ($ou_path -split ",")[-1..-($ou_array.Length)] | %{
        $ou_name = ($_ -split "=")[1]
        $XPath = (Get-XPath $node)
        $XPath = $XPath.Substring(0,$XPath.Length-1)

        [xml]$xml = Get-Content $xml_path
        $node_to_insert_from = $xml.SelectSingleNode($XPath)
        $new_node = $xml.CreateElement("OU")
        $new_node.setAttribute("NAME",$ou_name) 
        $node_to_insert_from.AppendChild($new_node)
        $xml.save("Z:\AD-Tiering\lib\templates\Tiering-OU-populated.xml") 

        $node_path = Get-LdapPathFromXML $node "STRUCTURE"
        
        if($TIERING_MAP.ContainsKey($ou_path)){
            $TIERING_MAP[$ou_path] += $node_path
        }else{
            $TIERING_MAP.Add($ou_path,@($node_path)) 
        }  
        
    }
}

# Search all nodes where attribute "Class" matches the object class. Processing each node with $function
function Search-XMLNodeByClass([String]$object_path,
                               [String]$object_class,
                               [String]$xml_path,
                               [ScriptBlock]$function
                               ){
    #Strips LDAP path from CN, keep only OU paths
    if($object_path -match "CN=[^,]*,(OU=.*)"){
        $ou_path = $Matches[1]
        $Matches.Clear()
        
        $nodes = Select-Xml "//*[@Class='$($object_class)']" $xml_path
        $nodes | %{
            if(!$TIERING_MAP.ContainsKey($ou_path)){
                Invoke-Command $function -ArgumentList $ou_path, $_.Node, $xml_path
            }     
        } 
    }                            


}