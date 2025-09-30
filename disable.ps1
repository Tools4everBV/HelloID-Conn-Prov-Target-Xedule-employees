##################################################
# HelloID-Conn-Prov-Target-Xedule-employees-Disable
# PowerShell V2
##################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
function Resolve-Xedule-employeesError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            ScriptLineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
            Line             = $ErrorObject.InvocationInfo.Line
            ErrorDetails     = $ErrorObject.Exception.Message
            FriendlyMessage  = $ErrorObject.Exception.Message
        }
        if (-not [string]::IsNullOrEmpty($ErrorObject.ErrorDetails.Message)) {
            $httpErrorObj.ErrorDetails = $ErrorObject.ErrorDetails.Message
        } elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            if ($null -ne $ErrorObject.Exception.Response) {
                $streamReaderResponse = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
                if (-not [string]::IsNullOrEmpty($streamReaderResponse)) {
                    $httpErrorObj.ErrorDetails = $streamReaderResponse
                }
            }
        }
        try {
            $errorDetailsObject = ($httpErrorObj.ErrorDetails | ConvertFrom-Json)
            $httpErrorObj.FriendlyMessage = $errorDetailsObject.message
        } catch {
            $httpErrorObj.FriendlyMessage = "Error: [$($httpErrorObj.ErrorDetails)] [$($_.Exception.Message)]"
        }
        Write-Output $httpErrorObj
    }
}

function Get-XeduleToken {
    param ()
    $headers = @{
        'Content-Type' = 'application/x-www-form-urlencoded'
    }
    $body = @{
        grant_type    = 'client_credentials'
        client_id     = $actionContext.Configuration.ClientId
        client_secret = $actionContext.Configuration.ClientSecret
        scope         = 'api://xedule-connect/.default'
    }
    $splatGetToken = @{
        Uri     = "$($actionContext.Configuration.TokenUrl)"
        Method  = 'POST'
        Headers = $headers
        Body    = $body
    }
    $tokenResponse = Invoke-RestMethod @splatGetToken
    Write-Output $tokenResponse.access_token
}
#endregion

try {
    # Verify if [aRef] has a value
    if ([string]::IsNullOrEmpty($($actionContext.References.Account))) {
        throw 'The account reference could not be found'
    }

    # Get the token and set the headers
    $headers = @{
        'Ocp-Apim-Subscription-Key' = $actionContext.Configuration.OcpApimSubscriptionKey
        'Authorization'             = "Bearer $(Get-XeduleToken)"
    }

    Write-Information 'Verifying if a Xedule-employees account exists'
    $splatGetUserParams = @{
        Uri     = "$($actionContext.Configuration.BaseUrl)/employee-teams/api/Medewerker/ore/$($actionContext.Configuration.oreId)/id/$($actionContext.References.Account)?customer=$($actionContext.Configuration.Customer)"
        Method  = 'GET'
        headers = $headers
    }
    $correlatedAccount = (Invoke-RestMethod @splatGetUserParams).Object

    if ($null -ne $correlatedAccount) {
        $action = 'DisableAccount'
    } else {
        $action = 'NotFound'
    }

    # Process
    switch ($action) {
        'DisableAccount' {
            $splatUpdateParams = @{
                Uri         = "$($actionContext.Configuration.BaseUrl)/employee-teams/api/Medewerker/ore/$($actionContext.Configuration.oreId)?customer=$($actionContext.Configuration.Customer)"
                Method      = 'PATCH'
                Body        = @{
                    Id        = $actionContext.References.Account
                    UitDienst = "$((Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))"
                    InDienst  = @(
                        @{
                            From = (Get-Date).AddDays(-1).ToString('yyyy-MM-ddTHH:mm:ss')
                            To   = (Get-Date).AddDays(-1).ToString('yyyy-MM-ddTHH:mm:ss')
                        }
                    )
                } | ConvertTo-Json
                headers     = $headers
                ContentType = 'application/json; charset=utf-8'
            }


            if (-not($actionContext.DryRun -eq $true)) {
                Write-Information "Disabling Xedule-employees account with accountReference: [$($actionContext.References.Account)]"
                $null = Invoke-RestMethod @splatUpdateParams

            } else {
                Write-Information "[DryRun] Disable Xedule-employees account with accountReference: [$($actionContext.References.Account)], will be executed during enforcement"
            }

            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = 'Disable account was successful'
                    IsError = $false
                })
            break
        }

        'NotFound' {
            Write-Information "Xedule-employees account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = "Xedule-employees account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
                    IsError = $false
                })
            break
        }
    }
} catch {
    $outputContext.success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-Xedule-employeesError -ErrorObject $ex
        $auditMessage = "Could not disable Xedule-employees account. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    } else {
        $auditMessage = "Could not disable Xedule-employees account. Error: $($_.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
}