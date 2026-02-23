# Extract content.xml from ODT files
Add-Type -AssemblyName System.IO.Compression.FileSystem

$docDir = "c:\Users\phiworks\Documents"
$outDir = "c:\Users\phiworks\Desktop\LaoTrust_Project"

$files = Get-ChildItem -Path $docDir -Filter "*.odt" -File | Where-Object {
    ($_.Name -like "*02-20*" -and $_.Name -like "*LT-05*") -or
    ($_.Name -like "*02-20*" -and $_.Name -like "*LT-04*")
}

foreach ($f in $files) {
    $outName = if ($f.Name -match "LT-05") { "lt05_content.xml" } else { "lt04_content.xml" }
    $outPath = Join-Path $outDir $outName
    $zip = [System.IO.Compression.ZipFile]::OpenRead($f.FullName)
    $entry = $zip.Entries | Where-Object { $_.Name -eq "content.xml" }
    $stream = $entry.Open()
    $reader = New-Object System.IO.StreamReader($stream)
    $reader.ReadToEnd() | Set-Content -Path $outPath -Encoding UTF8
    $reader.Close()
    $zip.Dispose()
    Write-Host "Extracted: $outPath"
}
