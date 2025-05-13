# Check if the CSV file exists
$csvPath = "$PSScriptRoot\AD-Create-Users-List.csv"
if (-not (Test-Path $csvPath)) {
    Write-Error "The CSV file does not exist: $csvPath"
    exit
}

# Define the OU as a variable
$organizationalUnit = "OU=users-cop-ts,DC=example,DC=priv"  # Modify the path to your OU

# Define the UserPrincipalName as a variable
$userPrincipalNameDomain = "@example.priv"  # Modify the UPN domain

# Import data from the CSV file
$users = Import-Csv -Path $csvPath -Delimiter "," -Encoding UTF8

# List to save results
$output = @()

# Function to generate a random password
function New-RandomPassword {
    $length = 20
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*'
    return -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)] })
}

foreach ($user in $users) {
    # Check that required fields are not empty
    if (-not $user.Account -or -not $user.FirstName -or -not $user.LastName -or -not $user.Email) {
        Write-Warning "Missing data for user: FirstName=$($user.FirstName), LastName=$($user.LastName)"
        continue
    }

    # Check if the user already exists in AD
    if (Get-ADUser -Filter {SamAccountName -eq $user.Account}) {
        Write-Warning "The user $($user.Account) already exists in Active Directory. Skipping..."
        continue
    }

    # Generate a random password
    $password = New-RandomPassword
    $securePassword = ConvertTo-SecureString -AsPlainText $password -Force

    try {
        # Create a new user in AD using variables for UserPrincipalName and Path
        New-ADUser -GivenName $user.FirstName `
                   -Surname $user.LastName `
                   -Name $user.Account `
                   -DisplayName "$($user.FirstName) $($user.LastName)" `
                   -EmailAddress $user.Email `
                   -UserPrincipalName ($user.Account + $userPrincipalNameDomain) `
                   -AccountPassword $securePassword `
                   -Enabled $true `
                   -PasswordNeverExpires $false `
                   -ChangePasswordAtLogon $false `
                   -Path $organizationalUnit
        
        # Add the user to the specified groups
        if ($user.Groups) {
            $groups = $user.Groups -split ";"
            foreach ($group in $groups) {
                Add-ADGroupMember -Identity $group -Members $user.Account
            }
        } else {
            Write-Warning "Missing groups for user: Account=$($user.Account)"
        }

        # Add details to the result
        $output += [PSCustomObject]@{
            FirstName = $user.FirstName
            LastName  = $user.LastName
            Account   = $user.Account
            Password  = $password
            Status    = "Successfully created"
        }
    } catch {
        Write-Error "Error while creating user $($user.Account): $_"
        $output += [PSCustomObject]@{
            FirstName = $user.FirstName
            LastName  = $user.LastName
            Account   = $user.Account
            Password  = $password
            Status    = "Error during creation"
        }
    }
}

# Export results to a CSV file
$output | Export-Csv -Path "$PSScriptRoot\CreaUtentiAD-report.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Process completed. Details saved in the CSV file."
Write-Host "Report file: $PSScriptRoot\AD-Create-Users-report.csv"