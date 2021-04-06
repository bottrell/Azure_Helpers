# Azure_Helpers
Nifty little Azure Scripts that I put together for automating the intricacies of Azure. Feel free to use them as your heart desires! All documentation is listed below for the sake of convenience. Each presumes that the user is running in the correct subscription context with necessary permissions.

## Resize-disk-by-letter.ps1
Received a request to resize an Azure drive but didn't feel like going through the process of manually translating LUN to drive letter? Well look no further! This script takes in a drive letter and new size as parameters and automagically resizes the correct disk. No need to confuse yourself with mapping drive number to letter and then letter to LUN!

### Sample Run:
`$ Resize-disk-by-letter -letter d -size 512`

### Notes
- Doesn't take into account temporary drives, so if the script repeatedly fails, you're likely running it on an Azure provisioned temporary drive.
- Will prompt the user when the machine is going to need to be rebooted 
