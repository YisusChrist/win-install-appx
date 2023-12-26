# Reference: https://christitus.com/installing-appx-without-msstore/

param(
    [string]$productUrl = ""
)

if ([string]::IsNullOrWhiteSpace($productUrl)) {
    $productUrl = Read-Host "Enter the Microsoft Store product URL"
}

if ([string]::IsNullOrWhiteSpace($productUrl)) {
    Write-Host "No product URL provided. Exiting."
    exit
}

$apiUrl = "https://store.rg-adguard.net/api/GetFiles"

$downloadFolder = Join-Path $env:TEMP "StoreDownloads"
if (!(Test-Path $downloadFolder -PathType Container)) {
    New-Item $downloadFolder -ItemType Directory -Force
}

$body = @{
    type = 'url'
    url  = $productUrl
    ring = 'RP'
    lang = 'en-US'
}

$raw = Invoke-RestMethod -Method Post -Uri $apiUrl -ContentType 'application/x-www-form-urlencoded' -Body $body

$raw | Select-String '<tr style.*<a href=\"(?<url>.*)"\s.*>(?<text>.*)<\/a>' -AllMatches | 
    ForEach-Object { $_.Matches } | 
    ForEach-Object {
        $url = $_.Groups[1].Value
        $text = $_.Groups[2].Value
        Write-Host $text

        if ($text -match "_(x86|x64|neutral).*appx(|bundle)$") {
            $downloadFile = Join-Path $downloadFolder $text
            if (!(Test-Path $downloadFile)) {
                Invoke-WebRequest -Uri $url -OutFile $downloadFile
            }
        }
    }
