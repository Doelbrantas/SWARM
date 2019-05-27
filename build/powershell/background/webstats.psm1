<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

## The below is for interfacing with HiveOS.

function Send-WebStats {
    if ($global:Config.Hive_Params.HiveID -and -not (test-Path "/hive/miners")) {
        $global:WebSites | ForEach-Object {
            Get-WebModules $_
            $Stats = Set-Stats $_
            $response = $Stats | Invoke-WebCommand -Site $_ -Action "message"
            $response | ConvertTo-Json | Set-Content ".\build\txt\response.txt"
            if ($response) {
                if ($response.result.command -eq "batch") {
                    $batch = $response.result.commands
                    for ($b = 0; $b -lt $batch.count; $b++) {
                        $do_command = $batch[$b]
                        $do_command = $do_command -replace "@{", ""
                        $do_command = $do_command -replace "}", ""
                        $do_command = $do_command -split ";"
                        $do_command = $do_command -replace "amd_oc=", ""
                        $do_command = $do_command -replace "nvidia_oc=", ""
                        $parsed_batch = $do_command
                        $new_command = $do_command | ConvertFrom-StringData
                        $batch_command = [PSCustomObject]@{"result" = @{command = $new_command.Command; id = $new_command.id; $new_command.command = $parsed_batch } }
                        $SwarmResponse = Start-webcommand -command $batch_command -website $_
                    }
                }
                else { $SwarmResponse = Start-webcommand -command $response -website $_ }
                if ($SwarmResponse -ne $null) {
                    if ($SwarmResponse -eq "config") {
                        Write-Warning "Config Command Initiated- Restarting SWARM"
                        $MinerFile = ".\build\pid\miner_pid.txt"
                        if (Test-Path $MinerFile) { $MinerId = Get-Process -Id (Get-Content $MinerFile) -ErrorAction SilentlyContinue }
                        if ($MinerId) {
                            Stop-Process $MinerId
                            Start-Sleep -S 3
                        }
                        Start-Process ".\SWARM.bat"
                        Start-Sleep -S 3
                        Exit
                    }
                    if ($SwarmResponse -eq "stats") {
                        Write-Host "Hive Received Stats"
                    }
                    if ($SwarmResponse -eq "exec") {
                        Write-Host "Sent Command To Hive"
                    }
                    if ($SwarmResponse -eq "update") {
                        Write-Host "Update Completed- Exiting"
                        Exit
                    }
                }
            }
        }
    }
}