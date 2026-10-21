# Cell-by-cell check that assets/data/*.json match the source spreadsheet.
#   powershell -ExecutionPolicy Bypass -File tool/verify_catalog_json.ps1 -Xlsx "C:\path\to\file.xlsx"
param(
  [string]$Xlsx = "$env:USERPROFILE\Downloads\Job Lists for Pitchvilla Hiring App.xlsx",
  [string]$DataDir = (Join-Path $PSScriptRoot '..\assets\data')
)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($Xlsx)
function ReadEntry($name) { $e = $zip.GetEntry($name); $r = New-Object System.IO.StreamReader($e.Open(), [Text.Encoding]::UTF8); $t = $r.ReadToEnd(); $r.Close(); $t }
$ss = @(); foreach ($si in ([xml](ReadEntry 'xl/sharedStrings.xml')).sst.si) { $ss += [string]$si.InnerText }
function ColNum($ref) { $n = 0; foreach ($c in ($ref -replace '\d', '').ToCharArray()) { $n = $n * 26 + ([int][char]$c - 64) }; $n }
function Raw($file) {
  $rows = @{}
  foreach ($row in ([xml](ReadEntry $file)).worksheet.sheetData.row) {
    $h = @{}
    foreach ($c in $row.c) {
      $v = $null
      if ($c.t -eq 's') { $v = $ss[[int]$c.v] } elseif ($null -ne $c.v) { $v = [string]$c.v }
      if ($null -ne $v) { $h[(ColNum $c.r)] = $v }
    }
    $rows[[int]$row.r] = $h
  }
  $rows
}
$bad = 0
function Check($label, $expected, $actual) {
  $e = if ($null -eq $expected -or "$expected".Trim() -eq '') { $null } else { "$expected".Trim() }
  $a = if ($null -eq $actual -or "$actual".Trim() -eq '') { $null } else { "$actual".Trim() }
  if ($e -ne $a) { $script:bad++; if ($script:bad -le 10) { "MISMATCH $label : xlsx=[$e] json=[$a]" } }
}
$jobsX = Raw 'xl/worksheets/sheet1.xml'
$coursesX = Raw 'xl/worksheets/sheet2.xml'
$jobsJ = [IO.File]::ReadAllText((Join-Path $DataDir 'jobs.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json
$coursesJ = [IO.File]::ReadAllText((Join-Path $DataDir 'courses.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json
$jobKeys = 'id','startupId','company','city','sector','type','experience','department','position','description','salaryRange','internStipend','demoOpening'
$n = 0
for ($i = 0; $i -lt $jobsJ.Count; $i++) {
  $x = $jobsX[$i + 2]; $j = $jobsJ[$i]
  for ($c = 0; $c -lt 13; $c++) { Check "job row $($i + 2) $($jobKeys[$c])" $x[$c + 1] $j.($jobKeys[$c]); $n++ }
}
$courseKeys = 'department','skillName','courseDuration','durationMonths'
for ($i = 0; $i -lt $coursesJ.Count; $i++) {
  $x = $coursesX[$i + 2]; $j = $coursesJ[$i]
  for ($c = 0; $c -lt 3; $c++) { Check "course row $($i + 2) $($courseKeys[$c])" $x[$c + 1] $j.($courseKeys[$c]); $n++ }
  if ([math]::Abs([double]::Parse($x[4], [Globalization.CultureInfo]::InvariantCulture) - [double]$j.durationMonths) -gt 1e-9) { $bad++; "MISMATCH course row $($i + 2) months"}; $n++
}
$dataRowsJobs = ($jobsX.Keys | Where-Object { $_ -ge 2 -and $jobsX[$_].Count -gt 0 }).Count
$dataRowsCourses = ($coursesX.Keys | Where-Object { $_ -ge 2 -and $coursesX[$_].Count -gt 0 }).Count
"jobs: json=$($jobsJ.Count) xlsx=$dataRowsJobs | courses: json=$($coursesJ.Count) xlsx=$dataRowsCourses"
$stip = @($jobsJ | Where-Object { $_.internStipend }).Count; $ints = @($jobsJ | Where-Object { $_.type -eq 'Internship' }).Count
$stipOnInterns = @($jobsJ | Where-Object { $_.internStipend -and $_.type -eq 'Internship' }).Count
"stipend present on $stip rows ($stipOnInterns of $ints internships)"
"cells compared: $n   mismatches: $bad"
$zip.Dispose()
if ($bad -gt 0 -or $jobsJ.Count -ne $dataRowsJobs -or $coursesJ.Count -ne $dataRowsCourses) { exit 1 } else { "OK: JSON matches the spreadsheet exactly" }
