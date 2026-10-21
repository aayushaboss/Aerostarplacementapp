# Converts "Job Lists for Pitchvilla Hiring App.xlsx" into the two JSON assets the
# app loads (assets/data/jobs.json and assets/data/courses.json).
#
#   powershell -ExecutionPolicy Bypass -File tool/xlsx_to_json.ps1 -Xlsx "C:\path\to\file.xlsx"
#
# Values are copied verbatim (only trimmed). Normalisation ("Full Time" ->
# "Full-time", placeholders for fields the sheet lacks) happens in Dart, in
# lib/mockData/catalog_loader.dart, so this file stays a faithful copy of the sheet.
param(
  [string]$Xlsx = "$env:USERPROFILE\Downloads\Job Lists for Pitchvilla Hiring App.xlsx",
  [string]$OutDir = (Join-Path $PSScriptRoot '..\assets\data')
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($Xlsx)

function ReadEntry($name) {
  $e = $zip.GetEntry($name)
  $r = New-Object System.IO.StreamReader($e.Open(), [Text.Encoding]::UTF8)
  $t = $r.ReadToEnd(); $r.Close(); $t
}

# Shared strings. InnerText (not .t) so rich-text cells come through whole.
$ss = New-Object System.Collections.Generic.List[string]
foreach ($si in ([xml](ReadEntry 'xl/sharedStrings.xml')).sst.si) { $ss.Add([string]$si.InnerText) }

function ColNum($ref) {
  $n = 0
  foreach ($c in ($ref -replace '\d', '').ToCharArray()) { $n = $n * 26 + ([int][char]$c - 64) }
  $n
}

# Which sheet file is which: resolve through workbook.xml + its rels.
$wb = [xml](ReadEntry 'xl/workbook.xml')
$rels = [xml](ReadEntry 'xl/_rels/workbook.xml.rels')
$target = @{}
foreach ($r in $rels.Relationships.Relationship) { $target[$r.Id] = $r.Target }
function SheetFile($sheetName) {
  foreach ($s in $wb.workbook.sheets.sheet) {
    if ($s.name.Trim() -eq $sheetName) {
      $id = $s.GetAttribute('id', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')
      return 'xl/' + ($target[$id] -replace '^/?(xl/)?', '')
    }
  }
  throw "Sheet '$sheetName' not found"
}

function LoadRows($file) {
  $s = [xml](ReadEntry $file)
  $out = New-Object System.Collections.Generic.List[hashtable]
  foreach ($row in $s.worksheet.sheetData.row) {
    $h = @{}
    foreach ($c in $row.c) {
      $v = $null
      if ($c.t -eq 's') { $v = $ss[[int]$c.v] } elseif ($null -ne $c.v) { $v = [string]$c.v }
      if ($null -ne $v -and "$v".Trim() -ne '') { $h[(ColNum $c.r)] = "$v".Trim() }
    }
    $out.Add($h)
  }
  , $out
}

function Cell($h, $i) { if ($h.ContainsKey($i)) { $h[$i] } else { $null } }

$jobRows = LoadRows (SheetFile 'Jobs')
$courseRows = LoadRows (SheetFile 'Courses')

$jobs = @()
for ($i = 1; $i -lt $jobRows.Count; $i++) {
  $r = $jobRows[$i]
  if ($r.Count -eq 0) { continue }
  $jobs += [ordered]@{
    id           = Cell $r 1
    startupId    = Cell $r 2
    company      = Cell $r 3
    city         = Cell $r 4
    sector       = Cell $r 5
    type         = Cell $r 6
    experience   = Cell $r 7
    department   = Cell $r 8
    position     = Cell $r 9
    description  = Cell $r 10
    salaryRange  = Cell $r 11
    internStipend = Cell $r 12
    demoOpening  = Cell $r 13
  }
}

$courses = @()
for ($i = 1; $i -lt $courseRows.Count; $i++) {
  $r = $courseRows[$i]
  if ($r.Count -eq 0) { continue }
  $courses += [ordered]@{
    department     = Cell $r 1
    skillName      = Cell $r 2
    courseDuration = Cell $r 3
    durationMonths = [double]::Parse((Cell $r 4), [Globalization.CultureInfo]::InvariantCulture)
  }
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)   # no BOM
[IO.File]::WriteAllText((Join-Path $OutDir 'jobs.json'), (ConvertTo-Json -InputObject $jobs -Depth 4 -Compress), $utf8)
[IO.File]::WriteAllText((Join-Path $OutDir 'courses.json'), (ConvertTo-Json -InputObject $courses -Depth 4 -Compress), $utf8)
$zip.Dispose()
"jobs: $($jobs.Count)   courses: $($courses.Count)   -> $OutDir"
