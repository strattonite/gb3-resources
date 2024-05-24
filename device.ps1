# Run 'usbipd list' command and filter for the line containing 'Serial'

wsl

exit

$result = usbipd list | Select-String -Pattern "Serial"

# Output the result
if ($result) {
    Write-Output "USB device(s) found:"
    $result
    $id = (-split $result)[0]
    usbipd attach --wsl --busid $id
} else {
    Write-Output "No USB device(s) found."
}

