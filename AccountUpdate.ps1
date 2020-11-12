
#Initialize default properties
$p = $person | ConvertFrom-Json;
$m = $manager | ConvertFrom-Json;
$config = $configuration | ConvertFrom-Json
$success = $False;
$auditMessage = "for person " + $p.DisplayName;

$account_guid = New-Guid

#Change mapping here
$account = [PSCustomObject]@{
    displayName = $p.DisplayName;
    firstName= $p.Name.NickName;
    lastName= $p.Name.FamilyName;
    userName = $p.UserName;
    externalId = $account_guid;
    title = $p.PrimaryContract.Title.Name;
    department = $p.PrimaryContract.Department.DisplayName;
    startDate = $p.PrimaryContract.StartDate;
    endDate = $p.PrimaryContract.EndDate;
    manager = $p.PrimaryManager.DisplayName;
}

$externalID = $p.ExternalId
$UPN = $p.Accounts.MicrosoftActiveDirectorysvdlocal.userPrincipalName #check your own dependent system name!!
$clientId = $config.clientid
$clientSecret = $config.clientsecret
$TenantId = $config.tenantid

function New-RaetSession { 
    [CmdletBinding()]
    param (
        [Alias("Param1")] 
        [parameter(Mandatory = $true)]  
        [string]      
        $ClientId,

        [Alias("Param2")] 
        [parameter(Mandatory = $true)]  
        [string]
        $ClientSecret,

        [Alias("Param3")] 
        [parameter(Mandatory = $false)]  
        [string]
        $TenantId
    )
   
    #Check if the current token is still valid
    if (Confirm-AccessTokenIsValid -eq $true) {       
        return
    }

    $url = "https://api.raet.com/authentication/token"
    $authorisationBody = @{
        'grant_type'    = "client_credentials"
        'client_id'     = $ClientId
        'client_secret' = $ClientSecret
    } 
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
        $result = Invoke-WebRequest -Uri $url -Method Post -Body $authorisationBody -ContentType 'application/x-www-form-urlencoded' -Headers @{'Cache-Control' = "no-cache" } -Proxy:$Proxy -UseBasicParsing
        $accessToken = $result.Content | ConvertFrom-Json
        $Script:expirationTimeAccessToken = (Get-Date).AddSeconds($accessToken.expires_in)

        $Script:AuthenticationHeaders = @{
            'X-Client-Id'      = $ClientId;
            'Authorization'    = "Bearer $($accessToken.access_token)";
            'X-Raet-Tenant-Id' = $TenantId;
           
        }     
    }
    catch {
        if ($_.ErrorDetails) {
            Write-Error $_.ErrorDetails
        }
        elseif ($_.Exception.Response) {
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $responseReader = $reader.ReadToEnd()
            $errorExceptionStreamResponse = $responseReader | ConvertFrom-Json
            $reader.Dispose()
            Write-Error $errorExceptionStreamResponse.error.message
        }
        else {
            Write-Error "Something went wrong while connecting to the RAET API";
        }
        Exit;
    } 
}

function Confirm-AccessTokenIsValid {
    if ($null -ne $Script:expirationTimeAccessToken) {
        if ((Get-Date) -le $Script:expirationTimeAccessToken) {
            return $true
        }        
    }
    return $false    
}

if(-Not($dryRun -eq $True)) {

try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
    $accessTokenValid = Confirm-AccessTokenIsValid
    if ($accessTokenValid -ne $true) {
        New-RaetSession -ClientId $clientId -ClientSecret $clientSecret
    }
    
    If ($null -ne $UPN) {
        $userUPN = [PSCustomObject]@{
            id = $UPN
        }
        $identity = $userUPN | ConvertTo-Json
        $PatchUrl = "https://api.raet.com/iam/v1.0/users(employeeId=$externalID)/identity"
        Invoke-WebRequest -Uri $PatchUrl -Method PATCH -Headers $Script:AuthenticationHeaders -ContentType "application/json" -Body $identity
    }
    Write-Verbose "Update RAET user identity successfull" -Verbose
} 
Catch {
    Write-Error "Could update RAET user identity, message: $($_.Exception.Message)"
}

}

$success = $True;
$auditMessage = "for person " + $p.DisplayName;

#build up result
$result = [PSCustomObject]@{ 
	Success= $success;
	AccountReference= $account_guid;
	AuditDetails=$auditMessage;
    Account = $account;

    # Optionally return data for use in other systems
    ExportData = [PSCustomObject]@{
        displayName = $account.DisplayName;
        userName = $account.UserName;
        externalId = $account_guid;
    };
};

#send result back
Write-Output $result | ConvertTo-Json -Depth 10