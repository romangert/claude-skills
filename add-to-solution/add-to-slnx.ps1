[CmdletBinding(PositionalBinding = $false)]
param(
    # Files or directories to add. Directories are expanded to every non-ignored file inside.
    [Parameter(Mandatory, ValueFromRemainingArguments)]
    [string[]]$Path,
    # Path to the .slnx; defaults to the only .slnx in the repo root.
    [string]$Solution
)

$ErrorActionPreference = 'Stop'
$root = (git rev-parse --show-toplevel) -replace '/', '\'
if (-not $Solution) {
    $found = @(Get-ChildItem -Path $root -Filter *.slnx -File)
    if ($found.Count -ne 1) { throw "Expected exactly one .slnx in $root, found $($found.Count). Use -Solution." }
    $Solution = $found[0].FullName
}
$slnDir = Split-Path $Solution -Parent

# Resolve inputs to repo-relative, forward-slash file paths.
$files = foreach ($p in $Path) {
    $full = if ([IO.Path]::IsPathRooted($p)) { $p } else { Join-Path (Get-Location) $p }
    if (Test-Path $full -PathType Container) {
        git -C $full ls-files --cached --others --exclude-standard | ForEach-Object { Join-Path $full $_ }
    } elseif (Test-Path $full -PathType Leaf) {
        $full
    } else {
        Write-Warning "Not found, skipped: $p"
    }
}

$doc = New-Object System.Xml.XmlDocument
$doc.PreserveWhitespace = $false
$doc.Load($Solution)
$sol = $doc.DocumentElement
$firstProject = $sol.SelectSingleNode('Project')
$added = 0

foreach ($f in $files) {
    $abs = (Resolve-Path $f).Path
    $prefix = $slnDir.TrimEnd('\') + '\'
    if (-not $abs.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { Write-Warning "Outside solution dir, skipped: $f"; continue }
    $rel = $abs.Substring($prefix.Length) -replace '\\', '/'
    # Skip files already listed anywhere (including Project entries)
    if ($sol.SelectSingleNode("//File[@Path='$($rel.Replace("'", "''"))']")) { continue }

    $dir = if ($rel.Contains('/')) { '/' + $rel.Substring(0, $rel.LastIndexOf('/')) + '/' } else { '/Solution Items/' }
    $folder = $sol.SelectSingleNode("Folder[@Name='$dir']")
    if (-not $folder) {
        $folder = $doc.CreateElement('Folder')
        $folder.SetAttribute('Name', $dir)
        if ($firstProject) { [void]$sol.InsertBefore($folder, $firstProject) } else { [void]$sol.AppendChild($folder) }
    }
    $el = $doc.CreateElement('File')
    $el.SetAttribute('Path', $rel)
    [void]$folder.AppendChild($el)
    Write-Host "added $rel -> $dir"
    $added++
}

if ($added -gt 0) {
    $settings = New-Object System.Xml.XmlWriterSettings
    $settings.Indent = $true
    $settings.IndentChars = '  '
    $settings.OmitXmlDeclaration = $true
    $settings.Encoding = New-Object System.Text.UTF8Encoding($false)
    $writer = [System.Xml.XmlWriter]::Create($Solution, $settings)
    try { $doc.Save($writer) } finally { $writer.Dispose() }
}
Write-Host "$added file(s) added to $(Split-Path $Solution -Leaf)"
