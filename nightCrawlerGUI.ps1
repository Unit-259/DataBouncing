function Invoke-NightcrawlerGui {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    # Create a new form with a dark background and a bit more width.
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "NightCrawler Exfiltration"
    $form.Size = New-Object System.Drawing.Size(540, 420)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $form.MaximizeBox = $false
    
    # Use a monospaced font for a "hacker" vibe, and a dark background color.
    $form.Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Regular)
    $form.BackColor = [System.Drawing.Color]::FromArgb(25,25,25)
    
    # Helper function to style controls with a dark theme and green text.
    function Style-Control([System.Windows.Forms.Control]$control) {
        $control.ForeColor = [System.Drawing.Color]::Lime
        if ($control -is [System.Windows.Forms.Button]) {
            $control.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
        }
        elseif ($control -is [System.Windows.Forms.TextBox]) {
            $control.BackColor = [System.Drawing.Color]::FromArgb(35,35,35)
        }
        else {
            $control.BackColor = $form.BackColor
        }
    }
    
    #############################
    # Identifier Controls
    #############################
    $lblIdentifier = New-Object System.Windows.Forms.Label
    $lblIdentifier.Location = New-Object System.Drawing.Point(20,20)
    $lblIdentifier.Size = New-Object System.Drawing.Size(120,20)
    $lblIdentifier.Text = "Identifier:"
    
    $txtIdentifier = New-Object System.Windows.Forms.TextBox
    $txtIdentifier.Location = New-Object System.Drawing.Point(150,20)
    $txtIdentifier.Size = New-Object System.Drawing.Size(350,20)
    
    #############################
    # Domain Controls
    #############################
    $lblDomain = New-Object System.Windows.Forms.Label
    $lblDomain.Location = New-Object System.Drawing.Point(20,60)
    $lblDomain.Size = New-Object System.Drawing.Size(120,20)
    $lblDomain.Text = "Domain:"
    
    $txtDomain = New-Object System.Windows.Forms.TextBox
    $txtDomain.Location = New-Object System.Drawing.Point(150,60)
    $txtDomain.Size = New-Object System.Drawing.Size(350,20)
    
    #############################
    # URL Controls (comma separated)
    #############################
    $lblUrl = New-Object System.Windows.Forms.Label
    $lblUrl.Location = New-Object System.Drawing.Point(20,100)
    $lblUrl.Size = New-Object System.Drawing.Size(120,20)
    $lblUrl.Text = "URL(s):"
    
    $txtUrl = New-Object System.Windows.Forms.TextBox
    $txtUrl.Location = New-Object System.Drawing.Point(150,100)
    $txtUrl.Size = New-Object System.Drawing.Size(350,20)
    
    #############################
    # File Path Controls
    #############################
    $lblFilePath = New-Object System.Windows.Forms.Label
    $lblFilePath.Location = New-Object System.Drawing.Point(20,140)
    $lblFilePath.Size = New-Object System.Drawing.Size(120,20)
    $lblFilePath.Text = "File Path:"
    
    $txtFilePath = New-Object System.Windows.Forms.TextBox
    $txtFilePath.Location = New-Object System.Drawing.Point(150,140)
    $txtFilePath.Size = New-Object System.Drawing.Size(280,20)
    
    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Location = New-Object System.Drawing.Point(440,140)
    $btnBrowse.Size = New-Object System.Drawing.Size(60,20)
    $btnBrowse.Text = "Browse"
    $btnBrowse.Add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtFilePath.Text = $openFileDialog.FileName
        }
    })
    
    #############################
    # Encryption Check & Key Controls
    #############################
    $chkEncryption = New-Object System.Windows.Forms.CheckBox
    $chkEncryption.Location = New-Object System.Drawing.Point(20,180)
    $chkEncryption.Size = New-Object System.Drawing.Size(200,20)
    $chkEncryption.Text = "Enable AES Encryption"
    
    $lblEncryptionKey = New-Object System.Windows.Forms.Label
    $lblEncryptionKey.Location = New-Object System.Drawing.Point(20,220)
    $lblEncryptionKey.Size = New-Object System.Drawing.Size(120,20)
    $lblEncryptionKey.Text = "Encryption Key:"
    
    $txtEncryptionKey = New-Object System.Windows.Forms.TextBox
    $txtEncryptionKey.Location = New-Object System.Drawing.Point(150,220)
    $txtEncryptionKey.Size = New-Object System.Drawing.Size(350,20)
    $txtEncryptionKey.Enabled = $false
    
    $chkEncryption.Add_CheckedChanged({
        $txtEncryptionKey.Enabled = $chkEncryption.Checked
    })
    
    #############################
    # Run Button Control
    #############################
    $btnRun = New-Object System.Windows.Forms.Button
    $btnRun.Location = New-Object System.Drawing.Point(20,260)
    $btnRun.Size = New-Object System.Drawing.Size(480,30)
    $btnRun.Text = "Run NightCrawler"
    
    #############################
    # Output Text Box Control
    #############################
    $txtOutput = New-Object System.Windows.Forms.TextBox
    $txtOutput.Location = New-Object System.Drawing.Point(20,300)
    $txtOutput.Size = New-Object System.Drawing.Size(480,60)
    $txtOutput.Multiline = $true
    $txtOutput.ScrollBars = "Vertical"
    
    #############################
    # Add Controls to the Form
    #############################
    $form.Controls.AddRange(@(
        $lblIdentifier, $txtIdentifier,
        $lblDomain, $txtDomain,
        $lblUrl, $txtUrl,
        $lblFilePath, $txtFilePath,
        $btnBrowse,
        $chkEncryption,
        $lblEncryptionKey, $txtEncryptionKey,
        $btnRun,
        $txtOutput
    ))
    
    # Apply the dark theme style to all controls.
    foreach ($control in $form.Controls) {
        Style-Control $control
    }
    
    #############################
    # Helper Function to Append Output
    #############################
    function Append-Output($msg) {
        $txtOutput.AppendText("$msg`r`n")
    }
    
    #############################
    # Run Button Click Event
    #############################
    $btnRun.Add_Click({
        $identifier = $txtIdentifier.Text
        $domain = $txtDomain.Text
        # Split URLs on commas and trim spaces.
        $urls = $txtUrl.Text -split "," | ForEach-Object { $_.Trim() }
        $filePath = $txtFilePath.Text
        $encryptionEnabled = $chkEncryption.Checked
        $encryptionKey = $txtEncryptionKey.Text
    
        # Validate required fields.
        if ([string]::IsNullOrWhiteSpace($identifier) -or 
            [string]::IsNullOrWhiteSpace($domain) -or 
            [string]::IsNullOrWhiteSpace($txtUrl.Text) -or 
            [string]::IsNullOrWhiteSpace($filePath)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Please fill in all required fields (Identifier, Domain, URL(s), File Path).",
                "Error", 
                [System.Windows.Forms.MessageBoxButtons]::OK, 
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            return
        }
    
        # Clear output and run NightCrawler.
        $txtOutput.Clear()
        Append-Output "Starting NightCrawler exfiltration..."
        try {
            # Call the NightCrawler function. (Ensure the NightCrawler code is loaded.)
            Invoke-NightCrawler `
                -Identifier $identifier `
                -Domain $domain `
                -Urls $urls `
                -FilePath $filePath `
                -EncryptionEnabled:($encryptionEnabled) `
                -EncryptionKey $encryptionKey
    
            Append-Output "NightCrawler exfiltration completed."
        } catch {
            Append-Output "Error: $_"
        }
    })
    
    $form.Add_Shown({ $form.Activate() })
    [void]$form.ShowDialog()
}
