<#
# Synopsis: Module for CSV processing
# Author: h4n0sh1
# License : GPL-2.0
# Created: 05/09/2025
#>

function Import-MapFromCsv([String]$csv_path,
                           [Int]$key_index = 0,
                           [Int]$value_index = 2
                          ){
    $map = @{}
    $csv = Import-Csv -Path $csv_path
    $key_header = $csv[0].PSObject.Properties.Name[$key_index]
    $value_header = $csv[0].PSObject.Properties.Name[$value_index]
    $csv | %{
        $key = $_.($key_header)
        $value = $_.($value_header)
        if(!$map.ContainsKey($key)){
            $map.Add($key,$value)
        }else{
            $map[$key] += $value
        }
           
    }
    return $map
}