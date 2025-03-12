<#
.SYNOPSIS
    Invoke-DeadPool reconstructs a file from DNS log entries containing hex-encoded exfiltrated data.
.DESCRIPTION
    This script reads a DNS log file, extracts the sequence number and hex-encoded chunk from each DNS query,
    groups by the sequence number (to avoid duplicates), sorts the unique chunks by sequence,
    decodes each chunk individually, concatenates the resulting byte arrays, and, if encryption was enabled,
    decrypts the data using the provided AES key.
    Finally, the reconstructed file is written to disk.
.EXAMPLE
    Invoke-DeadPool -LogFile "\root\logs.txt" -Identifier "testid" -EncryptionEnabled -EncryptionKey "YourSecretKey" -OutputFile "ReconstructedFile.txt"
#>

# --- Function: Convert a hex string back to a byte array ---
function ConvertFrom-Hex {
    param(
        [Parameter(Mandatory = $true)][string]$HexString
    )
    $hexString = $HexString.ToUpper()
    $length = $hexString.Length / 2
    $byteArray = New-Object byte[] $length
    for ($i = 0; $i -lt $length; $i++) {
        $byteArray[$i] = [Convert]::ToByte($hexString.Substring($i * 2, 2), 16)
    }
    return $byteArray
}

# --- AES Decryption Function ---
function Decrypt-Data {
    param(
        [Parameter(Mandatory = $true)][byte[]]$Data,
        [Parameter(Mandatory = $true)][string]$Key
    )
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($Key)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $aes.Key = $md5.ComputeHash($keyBytes)
    $IV = $Data[0..15]
    $cipherText = $Data[16..($Data.Length - 1)]
    $aes.IV = $IV
    $decryptor = $aes.CreateDecryptor()
    return $decryptor.TransformFinalBlock($cipherText, 0, $cipherText.Length)
}

# --- Logging Function ---
function Log-Message {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

# --- Main Reconstruction Function ---
function Invoke-DeadPool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$LogFile,
        [Parameter(Mandatory = $true)][string]$Identifier,
        [switch]$EncryptionEnabled,
        [string]$EncryptionKey = "",
        [Parameter(Mandatory = $false)][string]$OutputFile = "ReconstructedFile.txt"
    )

    Log-Message "Reading log file: $LogFile"
    $logContent = Get-Content -Path $LogFile -Raw

    # Look for the word-boundary of your identifier followed by a dot,
    $pattern = "(?<=\b$Identifier\.)(\d{3})\.([0-9A-F]+)"
    $matches = [regex]::Matches($logContent, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($matches.Count -eq 0) {
        Log-Message "No matching DNS entries found using the specified pattern."
        return
    }

    $chunkList = @()
    foreach ($match in $matches) {
        $orderStr = $match.Groups[1].Value.Trim()
        $order = [int]$orderStr
        $chunkValue = $match.Groups[2].Value.Trim()
        $obj = [PSCustomObject]@{
            Order = $order
            Chunk = $chunkValue
        }
        $chunkList += $obj
    }

    # Group by sequence number and take the first instance for each
    $uniqueChunks = $chunkList | Group-Object -Property Order | ForEach-Object { $_.Group[0] }
    $sortedChunks = $uniqueChunks | Sort-Object -Property Order
    Log-Message "Extracted $($sortedChunks.Count) unique chunks (sorted by sequence number)."

    # Decode each chunk individually and concatenate the byte arrays.
    $decodedBytesList = New-Object System.Collections.Generic.List[byte]
    foreach ($chunkObj in $sortedChunks) {
        $decoded = ConvertFrom-Hex -HexString $chunkObj.Chunk
        $decodedBytesList.AddRange([byte[]]$decoded)
    }
    $dataBytes = $decodedBytesList.ToArray()
    Log-Message "Total concatenated byte array length: $($dataBytes.Length)"

    if ($EncryptionEnabled) {
        if ([string]::IsNullOrEmpty($EncryptionKey)) {
            Log-Message "Encryption enabled but no key provided. Aborting reconstruction."
            return
        }
        Log-Message "Decrypting data..."
        $totalLength = $dataBytes.Length
        if ($totalLength -lt 16) {
            Log-Message "Data length is too short to contain an IV. Aborting."
            return
        }
        $cipherTextLength = $totalLength - 16
        $remainder = $cipherTextLength % 16
        if ($remainder -ne 0) {
            Log-Message "Trimming $remainder extra byte(s) from reconstructed data to form a complete block."
            $expectedLength = $totalLength - $remainder
            $dataBytes = $dataBytes[0..($expectedLength - 1)]
            Log-Message "New concatenated byte array length: $($dataBytes.Length)"
        }
        try {
            $decryptedBytes = Decrypt-Data -Data $dataBytes -Key $EncryptionKey
        } catch {
            Log-Message "Decryption failed: $_"
            return
        }
        $dataBytes = $decryptedBytes
        Log-Message "Decryption complete. Decrypted data length: $($dataBytes.Length)"
    }

    [System.IO.File]::WriteAllBytes($OutputFile, $dataBytes)
    Log-Message "Reconstructed file written to: $OutputFile"
}
