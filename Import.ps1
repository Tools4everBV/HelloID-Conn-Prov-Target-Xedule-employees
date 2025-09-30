#################################################
# HelloID-Conn-Prov-Target-Xedule-eemployees-Import
# PowerShell V2
#################################################

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
    $headers = @{
        'Ocp-Apim-Subscription-Key' = $actionContext.Configuration.OcpApimSubscriptionKey
        'Authorization'             = "Bearer $(Get-XeduleToken)"
    }

    Write-Information 'Starting account data import'
    $start = 0
    $amount = 500
    $importedAccounts = [System.Collections.Generic.List[object]]::new()
    do {
        $urlWithSkipTake = "$($actionContext.Configuration.BaseUrl)/employee-teams/api/Medewerker/ore/$($actionContext.Configuration.oreId)?customer=$($actionContext.Configuration.Customer)&start=$start&aantal=$amount"
        $splatGetUserParams = @{
            Uri     = $urlWithSkipTake
            Method  = 'GET'
            headers = $headers
        }
        $importedAccountRaw = (Invoke-RestMethod @splatGetUserParams).Objects
        if ($importedAccountRaw.Count -gt 0) {
            $importedAccounts.AddRange($importedAccountRaw)
        }
        $start += $amount
    } until ($importedAccountRaw.count -lt $amount -or $actionContext.DryRun)

    # Map the imported data to the account field mappings
    foreach ($importedAccount in $importedAccounts) {
        $data = @{}
        foreach ($field in $actionContext.ImportFields) {
            $data[$field] = $importedAccount.$field
        }
        $isEnabled = if ($null -eq $importedAccount.InDienst) {
            $false
        } else {
            $true
        }

        $displayName = "$($importedAccount.Voornaam) $($importedAccount.Achternaam)".trim(' ')
        if ([string]::IsNullOrEmpty($displayName)) {
            $displayName = $importedAccount.Id
        }

        $login = "$($importedAccount.Login)".trim(' ')
        if ([string]::IsNullOrEmpty($login)) {
            $login = $importedAccount.Id
        }

        Write-Output @{
            AccountReference = $importedAccount.Id
            DisplayName      = $displayName
            UserName         = $login
            Enabled          = $isEnabled
            Data             = $data
        }
    }

    Write-Information 'Account data import completed'
} catch {
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-Xedule-employeesError -ErrorObject $ex
        Write-Warning "Could not import Xedule-employees account. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    } else {
        Write-Warning "Could not import Xedule-employees account. Error: $($ex.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
}
