Param (
	[Parameter(Mandatory = $true)][String]$server_ip,
	[Parameter(Mandatory = $true)][String]$auth_token,
	[Parameter(Mandatory = $true)][String]$account
)

$totalTime = 0
$currentCount = 0

while ((Test-Connection -ComputerName $server_ip -Count 1 -Quiet) -ne $true) {
	$currentCount = $currentCount + 1
	if ($currentCount -eq 10) {
		$totalTime += $currentCount
		$currentCount = 0
		Write-Host "$server_ip has not been reachable for $totalTime seconds"
	}
}

$url = ""

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Basic $auth_token")
$headers.Add("Content-Type", "application/x-www-form-urlencoded")
$message = "Your ping to $server_ip has succeeded"

$body = "To=%2B12319070011&From=%2B18662754907&Body=$message"

$response = Invoke-RestMethod "https://api.twilio.com/2010-04-01/Accounts/$account/Messages.json" -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json
