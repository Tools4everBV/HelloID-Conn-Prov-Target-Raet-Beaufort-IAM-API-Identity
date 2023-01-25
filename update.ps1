#####################################################
# HelloID-Conn-Prov-Source-RAET-IAM-API-User-Update
#
# Version: 1.1.2
#####################################################
# Initialize default values
$c = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$aref = $accountReference | ConvertFrom-Json
$success = $false
$auditLogs = [System.Collections.Generic.List[PSCustomObject]]::new()

# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

# Set debug logging
switch ($($c.isDebug)) {
    $true { $VerbosePreference = 'Continue' }
    $false { $VerbosePreference = 'SilentlyContinue' }
}
$InformationPreference = "Continue"
$WarningPreference = "Continue"

# Used to connect to RAET IAM API endpoints
$clientId = $c.clientid
$clientSecret = $c.clientsecret
$TenantId = $c.tenantid

$Script:AuthenticationUrl = "https://connect.visma.com/connect/token"
$Script:BaseUrl = "https://api.youforce.com"

#Change mapping here
$account = [PSCustomObject]@{
    displayName = $p.DisplayName
    externalId  = $aRef
    identity    = $p.Accounts.MicrosoftActiveDirectory.userPrincipalName
}

# # Troubleshooting
# $account = [PSCustomObject]@{
#     displayName = 'John Doe - Test (918030)'
#     externalId  = '999999'
#     identity    = 'j.doe@enyoi.org'
# }
# $dryRun = $false

#region functions
function Resolve-HTTPError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline
        )]
        [object]$ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            FullyQualifiedErrorId = $ErrorObject.FullyQualifiedErrorId
            MyCommand             = $ErrorObject.InvocationInfo.MyCommand
            RequestUri            = $ErrorObject.TargetObject.RequestUri
            ScriptStackTrace      = $ErrorObject.ScriptStackTrace
            ErrorMessage          = ''
        }
        if ($ErrorObject.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') {
            $httpErrorObj.ErrorMessage = $ErrorObject.ErrorDetails.Message
        }
        elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            $httpErrorObj.ErrorMessage = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
        }
        Write-Output $httpErrorObj
    }
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
    $accessTokenValid = Confirm-AccessTokenIsValid
    if ($true -eq $accessTokenValid) {
        return
    }

    try {
        # Set TLS to accept TLS, TLS 1.1 and TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

        $authorisationBody = @{
            'grant_type'    = "client_credentials"
            'client_id'     = $ClientId
            'client_secret' = $ClientSecret
            'tenant_id'     = $TenantId
        }        
        $splatAccessTokenParams = @{
            Uri             = $AuthenticationUrl
            Headers         = @{'Cache-Control' = "no-cache" }
            Method          = 'POST'
            ContentType     = "application/x-www-form-urlencoded"
            Body            = $authorisationBody
            UseBasicParsing = $true
        }

        Write-Verbose "Creating Access Token at uri '$($splatAccessTokenParams.Uri)'"

        $result = Invoke-RestMethod @splatAccessTokenParams
        if ($null -eq $result.access_token) {
            throw $result
        }

        $Script:expirationTimeAccessToken = (Get-Date).AddSeconds($result.expires_in)

        $Script:AuthenticationHeaders = @{
            'Authorization' = "Bearer $($result.access_token)"
            'Accept'        = "application/json"
        }

        Write-Verbose "Successfully created Access Token at uri '$($splatAccessTokenParams.Uri)'"
    }
    catch {
        # Clear verboseErrorMessage and auditErrorMessage to make sure it isn't filled with a previouw error message
        $verboseErrorMessage = $null
        $auditErrorMessage = $null

        $ex = $PSItem
        if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
            $errorObject = Resolve-HTTPError -Error $ex
    
            $verboseErrorMessage = $errorObject.ErrorMessage
    
            $auditErrorMessage = $errorObject.ErrorMessage
        }
    
        # If error message empty, fall back on $ex.Exception.Message
        if ([String]::IsNullOrEmpty($verboseErrorMessage)) {
            $verboseErrorMessage = $ex.Exception.Message
        }
        if ([String]::IsNullOrEmpty($auditErrorMessage)) {
            $auditErrorMessage = $ex.Exception.Message
        }

        Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"        

        throw "Error creating Access Token at uri ''$($splatAccessTokenParams.Uri)'. Please check credentials. Error Message: $auditErrorMessage"
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
#endregion functions

# Get current RAET user
try {
    Write-Verbose "Querying RAET user with employeeId '$($account.externalID)'"

    $accessTokenValid = Confirm-AccessTokenIsValid
    if ($true -ne $accessTokenValid) {
        New-RaetSession -ClientId $clientId -ClientSecret $clientSecret -TenantId $tenantId
    }

    $splatGetDataParams = @{
        Uri             = "$baseUrl/iam/v1.0/users(employeeId=$($account.externalID))"
        Headers         = $Script:AuthenticationHeaders
        Method          = 'GET'
        ContentType     = "application/json"
        UseBasicParsing = $true
    }

    Write-Verbose "Querying data from '$($splatGetDataParams.Uri)'"

    $currentAccount = Invoke-RestMethod @splatGetDataParams -Verbose:$false

    if ($null -eq $currentAccount.id) {
        throw "No RAET user found with employeeId '$($account.externalID)'"
    }

    $propertiesChanged = $null
    # Check if current Identity has a different value from mapped value. RAET IAM API will throw an error when trying to update this with the same value
    if ([string]$currentAccount.identityId -ne $account.identity -and $null -ne $account.identity) {
        $propertiesChanged += @('Identity')
    }
    if ($propertiesChanged) {
        Write-Verbose "Account property(s) required to update: [$($propertiesChanged -join ",")]"
        $updateAction = 'Update'
    }
    else {
        $updateAction = 'NoChanges'
    }
}
catch {
    $ex = $PSItem
    if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObject = Resolve-HTTPError -Error $ex

        $verboseErrorMessage = $errorObject.ErrorMessage

        $auditErrorMessage = $errorObject.ErrorMessage
    }

    # If error message empty, fall back on $ex.Exception.Message
    if ([String]::IsNullOrEmpty($verboseErrorMessage)) {
        $verboseErrorMessage = $ex.Exception.Message
    }
    if ([String]::IsNullOrEmpty($auditErrorMessage)) {
        $auditErrorMessage = $ex.Exception.Message
    }

    Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"

    if ($auditErrorMessage -Like "No RAET user found with employeeId '$($account.externalID)'") {
        $success = $false
        $auditLogs.Add([PSCustomObject]@{
                Action  = "UpdateAccount"
                Message = "No RAET user found with employeeId '$($account.externalID)'. Possibly deleted."
                IsError = $true
            })
        Write-Warning "DryRun: No RAET user found with employeeId '$($account.externalID)'. Possibly deleted."
    }
    else {
        $success = $false  
        $auditLogs.Add([PSCustomObject]@{
                Action  = "UpdateAccount"
                Message = "Error querying RAET user with employeeId '$($account.externalID)'. Error Message: $auditErrorMessage"
                IsError = $True
            })
    }
}

if ($null -ne $currentAccount.id) {
    switch ($updateAction) {
        'Update' {
            try {
                $updateAccount = [PSCustomObject]@{
                    id = $account.identity
                }
                $body = ($updateAccount | ConvertTo-Json -Depth 10)    

                $splatWebRequest = @{
                    Uri             = "$baseUrl/iam/v1.0/users(employeeId=$($account.externalID))/identity"
                    Headers         = $Script:AuthenticationHeaders
                    Method          = 'PATCH'
                    Body            = ([System.Text.Encoding]::UTF8.GetBytes($body))
                    ContentType     = "application/json;charset=utf-8"
                    UseBasicParsing = $true
                }
            
                if (-not($dryRun -eq $true)) {
                    Write-Verbose "Updating RAET user with employeeId '$($account.externalID)'. Current identity: $($currentAccount.identityId). New identity: $($account.identity)"

                    $updatedAccount = Invoke-RestMethod @splatWebRequest -Verbose:$false

                    $success = $true
                    $auditLogs.Add([PSCustomObject]@{
                            Action  = "UpdateAccount"
                            Message = "Successfully updated RAET user with employeeId '$($account.externalID)'"
                            IsError = $false
                        })
                }
                else {
                    Write-Warning "DryRun: Would update RAET user with employeeId '$($account.externalID)'. Current identity: $($currentAccount.identityId). New identity: $($account.identity)"
                }
                break
            }
            catch {
                $ex = $PSItem
                if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
                    $errorObject = Resolve-HTTPError -Error $ex
                    
                    $verboseErrorMessage = $errorObject.ErrorMessage
                    
                    $auditErrorMessage = $errorObject.ErrorMessage
                }
                    
                # If error message empty, fall back on $ex.Exception.Message
                if ([String]::IsNullOrEmpty($verboseErrorMessage)) {
                    $verboseErrorMessage = $ex.Exception.Message
                }
                if ([String]::IsNullOrEmpty($auditErrorMessage)) {
                    $auditErrorMessage = $ex.Exception.Message
                }
                    
                $ex = $PSItem
                $verboseErrorMessage = $ex
                        
                Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"
                        
                $success = $false  
                $auditLogs.Add([PSCustomObject]@{
                        Action  = "UpdateAccount"
                        Message = "Error updating RAET user with employeeId '$($account.externalID)'. Current identity: $($currentAccount.identityId). New identity: $($account.identity). Error Message: $auditErrorMessage"
                        IsError = $True
                    })
            }
        }
        'NoChanges' {
            Write-Verbose "No changes to RAET user with employeeId '$($account.externalID)'"

            if (-not($dryRun -eq $true)) {
                $success = $true
                $auditLogs.Add([PSCustomObject]@{
                        Action  = "UpdateAccount"
                        Message = "Successfully updated RAET user with employeeId '$($account.externalID)'. (No Changes needed)"
                        IsError = $false
                    })
            }
            else {
                Write-Warning "DryRun: No changes to RAET user with employeeId '$($account.externalID)'"
            }
            break
        }
    }
}

#build up result
$result = [PSCustomObject]@{
    Success          = $success
    AccountReference = $aRef
    AuditLogs        = $auditLogs
    Account          = $account
    PreviousAccount  = $previousAccount

    # Optionally return data for use in other systems
    ExportData       = [PSCustomObject]@{
        displayName = $account.displayName
        identity    = $account.identity
        externalId  = $account.externalId
    }
}
#send result back
Write-Output $result | ConvertTo-Json -Depth 10