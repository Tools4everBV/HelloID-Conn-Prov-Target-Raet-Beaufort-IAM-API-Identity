#Initialize default properties
$p = $person | ConvertFrom-Json
$aref = $accountReference | ConvertFrom-Json
$config = $configuration | ConvertFrom-Json
$mRef = $managerAccountReference | ConvertFrom-Json;
$success = $False;
$auditLogs = New-Object Collections.Generic.List[PSCustomObject];

$clientId = $config.clientid
$clientSecret = $config.clientsecret
$TenantId = $config.tenantid

# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

#Change mapping here
$account = [PSCustomObject]@{
    displayName     = $p.DisplayName;
    externalId      = $p.externalID;    
    identity        = $p.Accounts.MicrosoftActiveDirectory.userPrincipalName;    
}

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
    } catch {
        if ($_.ErrorDetails) {
            Write-Verbose -Verbose $_.ErrorDetails
        } elseif ($_.Exception.Response) {
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $responseReader = $reader.ReadToEnd()
            $errorExceptionStreamResponse = $responseReader | ConvertFrom-Json
            $reader.Dispose()
            Write-Verbose -Verbose $errorExceptionStreamResponse.error.message
        } else {
            Write-Verbose -Verbose "Something went wrong while connecting to the RAET API";
        }
        throw  "Something went wrong while connecting to the RAET API";
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

try {
    If (($null -ne $account.identity)) {
        $accessTokenValid = Confirm-AccessTokenIsValid
        if ($accessTokenValid -ne $true) {
            New-RaetSession -ClientId $clientId -ClientSecret $clientSecret -TenantId $TenantId
        }

        $getUrl = "https://api.raet.com/iam/v1.0/users(employeeId=$($account.externalID))"       

        $getResult = Invoke-WebRequest -Uri $getUrl -Method GET -Headers $Script:AuthenticationHeaders -ContentType "application/json"

        $raetCurrentIdentity = ($getResult.content | ConvertFrom-Json).identityId

        if ($account.identity -ne $raetCurrentIdentity) {
        
            $userIdentity = [PSCustomObject]@{
                id = $account.identity
            }
            $identityBody = $userIdentity | ConvertTo-Json        

            $PatchUrl = "https://api.raet.com/iam/v1.0/users(employeeId=$($account.externalID))/identity"

            if (-Not($dryRun -eq $True)) {            
                $null = Invoke-WebRequest -Uri $PatchUrl -Method PATCH -Headers $Script:AuthenticationHeaders -ContentType "application/json" -Body $identityBody
            }
            $auditLogs.Add([PSCustomObject]@{
                    Message = "Updated RAET user identity $($aRef): New identity: $($account.identity)"
                    IsError = $false;
                });
    
            $success = $true;
        } else {
            $auditLogs.Add([PSCustomObject]@{
                    Message = "Skipped update of RAET user identity $($aRef): Identity equal in Raet: $($account.identity)"
                    IsError = $false;
                });
            $success = $true; 
        }
    } else {
        $auditLogs.Add([PSCustomObject]@{
                Message = "Error updating RAET user identity $($aRef): No new identity provided"
                IsError = $True
            });
        Write-Error "Error updating RAET user identity $($aRef): No new identity provided";  
    }
} catch {
    $auditLogs.Add([PSCustomObject]@{
            Message = "Error updating RAET user identity $($aRef): $($_)"
            IsError = $True
        });
    Write-Error "Error updating RAET user identity $($aRef): $($_)";  
}

#build up result
$result = [PSCustomObject]@{ 
    Success          = $success;
    AuditLogs        = $auditLogs
    Account          = $account;

    # Optionally return data for use in other systems
    ExportData       = [PSCustomObject]@{
        displayName = $account.DisplayName;
        identity    = $account.identity;
        externalId  = $account.externalId;
    };
};
#send result back
Write-Output $result | ConvertTo-Json -Depth 10
