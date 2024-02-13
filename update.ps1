#################################################
# HelloID-Conn-Prov-Target-Raet-Beaufort-IAM-API-Identity-Update
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# Used to connect to RAET IAM API endpoints
$Script:AuthenticationUrl = "https://connect.visma.com/connect/token"
$Script:BaseUrl = "https://api.youforce.com"

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
            Uri             = $Script:AuthenticationUrl
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

try {
    if (($actionContext.AccountCorrelated -eq $true) -or ($actionContext.Configuration.updateOnUpdate -eq $true)) {
              
        # Verify if [aRef] has a value
        if ([string]::IsNullOrEmpty($($actionContext.References.Account))) {
            throw 'The account reference could not be found'
        }

        $accessTokenValid = Confirm-AccessTokenIsValid
        if ($true -ne $accessTokenValid) {
            $splatRaetSession = @{
                ClientId     = $actionContext.Configuration.clientId
                ClientSecret = $actionContext.Configuration.clientSecret
                TenantId     = $actionContext.Configuration.tenantId
            }
            New-RaetSession @splatRaetSession
        }

        Write-Verbose "Verifying if a Raet Beaufort user account for [$($personContext.Person.DisplayName)] exists"

        $splatWebRequest = @{
            Uri             = "$($Script:BaseUri)/iam/v1.0/users(employeeId=$($actionContext.References.Account))"
            Headers         = $Script:AuthenticationHeaders
            Method          = 'GET'
            ContentType     = "application/json"
            UseBasicParsing = $true
        }
        $correlatedAccount = Invoke-RestMethod @splatWebRequest -Verbose:$false
        $outputContext.PreviousData = $correlatedAccount

        # Always compare the account against the current account in target system
        if ($null -ne $correlatedAccount.id) {
            $splatCompareProperties = @{
                ReferenceObject  = $correlatedAccount.PSObject.Properties
                DifferenceObject = $actionContext.Data.PSObject.Properties
            }
            $propertiesChanged = Compare-Object @splatCompareProperties -PassThru | Where-Object { $_.SideIndicator -eq '=>' }
            if ($propertiesChanged) {
                $action = 'UpdateAccount'
                $dryRunMessage = "Account property(s) required to update: $($propertiesChanged.Name -join ', ')"
            }
            else {
                $action = 'NoChanges'
                $dryRunMessage = 'No changes will be made to the account during enforcement'
            }
        }
        else {
            $action = 'NotFound'
            $dryRunMessage = "Raet Beaufort employee account for: [$($personContext.Person.DisplayName)] not found. Possibly deleted."
        }

        # Add a message and the result of each of the validations showing what will happen during enforcement
        if ($actionContext.DryRun -eq $true) {
            Write-Verbose "[DryRun] $dryRunMessage" -Verbose
        }

        # Process
        if (-not($actionContext.DryRun -eq $true)) {
            switch ($action) {
                'UpdateAccount' {
                    Write-Verbose "Updating Raet Beaufort user account with accountReference: [$($actionContext.References.Account)]"

                    # Some what confusing that the GET gives back a 'id' (aRef) and you have to PATCH the UPN on 'id' a well. This needs to be hardcoded
                    $updateAccount = [PSCustomObject]@{
                        id = $actionContext.Data.identity
                    }
                    $body = ($updateAccount | ConvertTo-Json -Depth 10)   

                    $splatWebRequest = @{
                        Uri             = "$($Script:BaseUri)/iam/v1.0/users(employeeId=$($account.externalID))/identity"
                        Headers         = $Script:AuthenticationHeaders
                        Method          = 'PATCH'
                        Body            = ([System.Text.Encoding]::UTF8.GetBytes($body))
                        ContentType     = "application/json;charset=utf-8"
                        UseBasicParsing = $true
                    }

                    $updatedAccount = Invoke-RestMethod @splatWebRequest -Verbose:$false

                    # Not sure if $updatedAccount gives back the result you updated. Else return $actionContext.Data
                    # $outputContext.Data = $actionContext.Data
                    $outputContext.Data = $updatedAccount

                    $outputContext.Success = $true
                    $outputContext.AuditLogs.Add([PSCustomObject]@{
                            Action  = $action
                            Message = "Delete account was successful, Account property(s) updated: [$($propertiesChanged.name -join ',')]"
                            IsError = $false
                        })
                    break
                }

                'NoChanges' {
                    Write-Verbose "No changes to Raet Beaufort user account with accountReference: [$($actionContext.References.Account)]"

                    $outputContext.Success = $true

                    # Remove this AuditLog?
                    $outputContext.AuditLogs.Add([PSCustomObject]@{
                            Message = 'No changes will be made to the account during enforcement'
                            IsError = $false
                        })
                    break
                }

                'NotFound' {
                    $outputContext.Success = $false
                    $outputContext.AuditLogs.Add([PSCustomObject]@{
                            Message = "Raet Beaufort user account [$($actionContext.References.Account)] for: [$($personContext.Person.DisplayName)] could not be found, possibly indicating that it could be deleted, or the account is not correlated"
                            IsError = $true
                        })
                    break
                }
            }
        }
    }
    else {
        Write-Verbose "No changes to Raet Beaufort user updateOnUpdate is [$($actionContext.Configuration.updateOnUpdate)]"
        $outputContext.Success = $true
    }
}
catch {
    $outputContext.success = $false
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
    
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = "Could not update Raet Beaufort user account. Error Message: $($auditErrorMessage)"
            IsError = $true
        })
}