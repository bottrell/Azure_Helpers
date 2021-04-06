$itemslist = @()

#Grab everything on the D Drive
$items = Get-ChildItem -Path "D:\"

#iterate through each and add them to the array to be returned to wrapper.ps1
foreach ($item in $items) {
    $itemslist += $item
}

return $itemslist