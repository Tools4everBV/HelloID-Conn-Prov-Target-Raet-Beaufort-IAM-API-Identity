$dryRun = $false

$config = ConvertFrom-Json $configuration

$clientId = $config.connection.clientId
$clientSecret = $config.connection.clientSecret
$tenantId = $config.connection.tenantId

#Initialize default properties
$p = $person | ConvertFrom-Json;
$m = $manager | ConvertFrom-Json;
$aRef = $accountReference | ConvertFrom-Json;
$mRef = $managerAccountReference | ConvertFrom-Json;
$success = $False;
$auditLogs = New-Object Collections.Generic.List[PSCustomObject];

# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

#Change mapping here
$account = [PSCustomObject]@{
    displayName     = $p.DisplayName;
    externalId      = $p.externalID;    
    currentIdentity = $aref
    identity        = $p.Accounts.ActiveDirectory.userPrincipalName;    
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
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq "Forbidden") {
            $errorMessage = "Something went wrong $($_.ScriptStackTrace). Error message: '$($_.Exception.Message)'"
        } elseif (![string]::IsNullOrEmpty($_.ErrorDetails.Message)) {
            $errorMessage = "Something went wrong $($_.ScriptStackTrace). Error message: '$($_.ErrorDetails.Message)'" 
        } else {
            $errorMessage = "Something went wrong $($_.ScriptStackTrace). Error message: '$($_)'" 
        }  
        throw $errorMessage
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

try{
    $aRef = $account.Identity;

    If (($null -ne $account.identity) -AND ($account.identity -ne $account.Currentidentity)) {
        $accessTokenValid = Confirm-AccessTokenIsValid
        if ($accessTokenValid -ne $true) {
            New-RaetSession -ClientId $clientId -ClientSecret $clientSecret -TenantId $TenantId
        }

        $getUrl = "https://api.raet.com/iam/v1.0/users(employeeId=$($account.externalID))"       
        $getResult = Invoke-WebRequest -Uri $getUrl -Method GET -Headers $Script:AuthenticationHeaders -ContentType "application/json"

        $raetCurrentIdentity = ($getResult.content | ConvertFrom-Json).identityId            
        
        if (($null -ne $raetCurrentIdentity) -AND ($account.identity -ne $raetCurrentIdentity)) {
    
            $userIdentity = [PSCustomObject]@{
                id = $account.identity
            }
            $identityBody = $userIdentity | ConvertTo-Json        

            $PatchUrl = "https://api.raet.com/iam/v1.0/users(employeeId=$($account.externalID))/identity"

            if (-Not($dryRun -eq $True)) {            
                $null = Invoke-WebRequest -Uri $PatchUrl -Method PATCH -Headers $Script:AuthenticationHeaders -ContentType "application/json" -Body $identityBody
            }

            $auditLogs.Add([PSCustomObject]@{
                Action = "CreateAccount"
                Message = "Updated RAET user identity $($aRef)"
                IsError = $false;
            });
    
            $success = $true;
        }
        else {
            $auditLogs.Add([PSCustomObject]@{
                Action = "CreateAccount"
                Message = "Skipped update of RAET user identity $($aRef); ID empty or equal in RAET"
                IsError = $false;
            });
    
            $success = $true;     
        }
    }else{
        $auditLogs.Add([PSCustomObject]@{
            Action = "CreateAccount"
            Message = "Skipped update of RAET user identity $($aRef); ID empty or equal in HelloID"
            IsError = $false;
        });
    
        $success = $true; 
    } 
}catch{
    $auditLogs.Add([PSCustomObject]@{
        Action = "CreateAccount"
        Message = "Error updating RAET user identity $($aRef): $($_)"
        IsError = $True
    });
    Write-Error $_;    
}


# Send results
$result = [PSCustomObject]@{
	Success= $success;
	AccountReference= $account.externalID;
	AuditLogs = $auditLogs;
    Account = $account;
    #PreviousAccount = $previousAccount;    

    # Optionally return data for use in other systems
    ExportData       = [PSCustomObject]@{
        displayName = $account.DisplayName;
        identity    = $account.identity;
        externalId  = $account.externalId;
    };
};
Write-Output $result | ConvertTo-Json -Depth 10;