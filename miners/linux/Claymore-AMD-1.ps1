##Miner Path Information
$Path = "$($amd.claymore_amd.path1)"
$Uri = "$($amd.claymore_amd.uri)"
$MinerName = "$($amd.claymore_amd.minername)"
$Build = "Tar"
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$ConfigType = "AMD1"

##Parse -GPUDevices
if($AMDDevices1 -ne ''){
$ClayDevices1  = $AMDDevices1 -split ","
$ClayDevices1  = Switch($ClayDevices1){"10"{"a"};"11"{"b"};"12"{"c"};"13"{"d"};"14"{"e"};"15"{"f"};"16"{"g"};"17"{"h"};"18"{"i"};"19"{"j"};"20"{"k"};default{"$_"};}
$ClayDevices1  = $ClayDevices1 | foreach {$_ -replace ("$($_)",",$($_)")}
$ClayDevices1  = $ClayDevices1 -join ""
$ClayDevices1  = $ClayDevices1.TrimStart(" ",",")  
$ClayDevices1 = $ClayDevices1 -replace(",","")
$Devices = $ClayDevices1}

##Get Configuration File
$GetConfig = "$dir\config\miners\claymore_amd.json"
try{$Config = Get-Content $GetConfig | ConvertFrom-Json}
catch{Write-Warning "Warning: No config found at $GetConfig"}

##Export would be /path/to/[SWARMVERSION]/build/export##
$ExportDir = Join-Path $dir "build\export"

##Prestart actions before miner launch
$Prestart = @()
$PreStart += "export LD_LIBRARY_PATH=$ExportDir"
$Config.$ConfigType.prestart | foreach {$Prestart += "$($_)"}

##Build Miner Settings
if($CoinAlgo -eq $null)
{
  $Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
  $MinerAlgo = $_
  $AlgoPools | Where Symbol -eq $MinerAlgo | foreach {
  if($Algorithm -eq "$($_.Algorithm)")
  {
  if($Config.$ConfigType.difficulty.$($_.Algorithm)){$Diff=",d=$($Config.$ConfigType.difficulty.$($_.Algorithm))"}
  [PSCustomObject]@{
  Symbol = "$($_.Algorithm)"
  MinerName = $MinerName
  Prestart = $PreStart
  Type = $ConfigType
  Path = $Path
  Devices = $Devices
  DeviceCall = "claymore"
  Arguments = "-platform 1 -mport 3336 -mode 1 -allcoins 1 -allpools 1 -epool $($_.Protocol)://$($_.Host):$($_.Port) -ewal $($_.User1) -epsw $($_.Pass1)$($Diff) -wd 0 -dbg -1 -eres 2 $($Config.$ConfigType.commands.$($_.Algorithm))"
  HashRates = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)}
  Quote = if($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)){$($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)*($_.Price)}else{0}
  PowerX = [PSCustomObject]@{$($_.Algorithm) = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_.Algorithm)_Power".Day)}elseif($Watts.$($_.Algorithm)."$($ConfigType)_Watts"){$Watts.$($_)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
  ocdmp = if($Config.$ConfigType.oc.$($_.Algorithm).dpm){$Config.$ConfigType.oc.$($_.Algorithm).dpm}else{$OC."default_$($ConfigType)".dpm}
  ocv = if($Config.$ConfigType.oc.$($_.Algorithm).v){$Config.$ConfigType.oc.$($_.Algorithm).v}else{$OC."default_$($ConfigType)".v}
  occore = if($Config.$ConfigType.oc.$($_.Algorithm).core){$Config.$ConfigType.oc.$($_.Algorithm).dpm}else{$OC."default_$($ConfigType)".core}
  ocmem = if($Config.$ConfigType.oc.$($_.Algorithm).mem){$Config.$ConfigType.oc.$($_.Algorithm).mem}else{$OC."default_$($ConfigType)".memory}
  ocmdmp = if($Config.$ConfigType.oc.$($_.Algorithm).mdpm){$Config.$ConfigType.oc.$($_.Algorithm).mdpm}else{$OC."default_$($ConfigType)".mdpm}
  FullName = "$($_.Mining)"
  API = "claymore"
  Port = 3336
  MinerPool = "$($_.Name)"
  Wrap = $false
  URI = $Uri
  BUILD = $Build
  Algo = "$($_.Algorithm)"
      }
     }
   }
 }
}