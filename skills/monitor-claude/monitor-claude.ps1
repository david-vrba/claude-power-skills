#Requires -Version 5.0
# monitor-claude.ps1 - Read-only Claude Code process health check (Windows).
# Enumerates claude.exe sessions + their cmd/node descendants, flags anomalies,
# and prints copy-pasteable kill commands. Does not kill anything itself.
# Run: powershell -NoProfile -File "<path-to-this-script>/monitor-claude.ps1"

# -- Thresholds (edit to tune sensitivity) ------------------------------------
$WARN_CLAUDE          = 20    # max claude.exe before warning
$WARN_NODE            = 80    # max node.exe total before warning
$WARN_CMD             = 80    # max cmd.exe total before warning
$WARN_AGE_H           = 8     # hours before an orphaned cmd.exe is flagged
$EXPECTED_PER_SESSION = 12    # expected cmd/node count per claude session

$snapshotLog = Join-Path $HOME ".claude\logs\process-snapshots.log"
$now = Get-Date

# -- Gather data --------------------------------------------------------------
try {
    $allProcs = Get-CimInstance Win32_Process -ErrorAction Stop |
        Select-Object ProcessId, ParentProcessId, Name, CreationDate
} catch {
    Write-Host "ERROR: Could not enumerate processes. Try running as administrator."
    exit 1
}

# Lookup and children-of hashtables for O(1) access
$procById   = @{}
$childrenOf = @{}
foreach ($p in $allProcs) {
    $procById[$p.ProcessId] = $p
    if (-not $childrenOf.ContainsKey($p.ParentProcessId)) {
        $childrenOf[$p.ParentProcessId] = [System.Collections.Generic.List[int]]::new()
    }
    $childrenOf[$p.ParentProcessId].Add([int]$p.ProcessId)
}

# Recursively collect all descendant PIDs of a given PID
function Get-DescendantPids([int]$ParentPid) {
    $result = [System.Collections.Generic.List[int]]::new()
    $children = $childrenOf[$ParentPid]
    if ($children) {
        foreach ($childPid in $children) {
            $result.Add($childPid)
            foreach ($d in (Get-DescendantPids $childPid)) { $result.Add($d) }
        }
    }
    return $result
}

# System-wide totals
$totalClaude = @($allProcs | Where-Object { $_.Name -eq 'claude.exe' }).Count
$totalCmd    = @($allProcs | Where-Object { $_.Name -eq 'cmd.exe'    }).Count
$totalNode   = @($allProcs | Where-Object { $_.Name -eq 'node.exe'   }).Count

# -- Per-session metrics ------------------------------------------------------
$claudeProcs = @($allProcs | Where-Object { $_.Name -eq 'claude.exe' })
$sessions    = [System.Collections.Generic.List[object]]::new()

foreach ($c in $claudeProcs) {
    $descPids  = @(Get-DescendantPids $c.ProcessId)
    $descProcs = $descPids | ForEach-Object { $procById[$_] } | Where-Object { $_ -ne $null }
    $cmdCount  = @($descProcs | Where-Object { $_.Name -eq 'cmd.exe'  }).Count
    $nodeCount = @($descProcs | Where-Object { $_.Name -eq 'node.exe' }).Count
    $ageH      = if ($c.CreationDate) { [math]::Round(($now - $c.CreationDate).TotalHours, 1) } else { -1 }
    $ageStr    = if ($ageH -ge 0) { "{0}h" -f $ageH } else { "?" }
    $orphan    = -not $procById.ContainsKey($c.ParentProcessId)

    $flags = [System.Collections.Generic.List[string]]::new()
    if ($orphan)                                   { $flags.Add("orphan") }
    if ($nodeCount -gt $EXPECTED_PER_SESSION * 2)  { $flags.Add("node-over") }

    $sessions.Add([PSCustomObject]@{
        PID    = $c.ProcessId
        AgeH   = $ageH
        AgeStr = $ageStr
        Cmd    = $cmdCount
        Node   = $nodeCount
        Flags  = $flags
        Status = if ($flags.Count -gt 0) { "WARN: " + ($flags -join ", ") } else { "OK" }
    })
}
$sessions = @($sessions | Sort-Object AgeH -Descending)

# -- Orphaned old cmd.exe (parent gone, age > WARN_AGE_H) --------------------
$oldOrphanCmds = @($allProcs | Where-Object {
    $_.Name -eq 'cmd.exe' -and
    (-not $procById.ContainsKey($_.ParentProcessId)) -and
    $_.CreationDate -ne $null -and
    ($now - $_.CreationDate).TotalHours -ge $WARN_AGE_H
})

# -- Output -------------------------------------------------------------------
$sep = "=" * 64
Write-Host ""
Write-Host $sep
Write-Host "             CLAUDE PROCESS HEALTH CHECK"
Write-Host $sep
Write-Host ("Timestamp : " + $now.ToString("yyyy-MM-dd HH:mm:ss"))
Write-Host ""

# Totals
$expectedCmd   = $totalClaude * $EXPECTED_PER_SESSION
$expectedNode  = $totalClaude * $EXPECTED_PER_SESSION
$claudeStatus  = if ($totalClaude -ge $WARN_CLAUDE) { "WARN" } else { "OK" }
$cmdStatus     = if ($totalCmd    -ge $WARN_CMD)    { "WARN" } else { "OK" }
$nodeStatus    = if ($totalNode   -ge $WARN_NODE)   { "WARN" } else { "OK" }

Write-Host "--- SYSTEM TOTALS ---"
Write-Host ("  claude.exe : {0,4}   [{1}]" -f $totalClaude, $claudeStatus)
Write-Host ("  cmd.exe    : {0,4}   [{1}]   expected ~{2} for {3} sessions" -f $totalCmd,  $cmdStatus,  $expectedCmd,  $totalClaude)
Write-Host ("  node.exe   : {0,4}   [{1}]   expected ~{2} for {3} sessions" -f $totalNode, $nodeStatus, $expectedNode, $totalClaude)
Write-Host ""

# Session table
Write-Host "--- SESSION BREAKDOWN ---"
if ($sessions.Count -eq 0) {
    Write-Host "  No active claude.exe sessions found."
} else {
    Write-Host ("  {0,-8} {1,-9} {2,-5} {3,-5}  {4}" -f "PID", "Age", "cmd", "node", "Status")
    Write-Host ("  {0,-8} {1,-9} {2,-5} {3,-5}  {4}" -f "--------", "---------", "-----", "-----", "------")
    foreach ($s in $sessions) {
        Write-Host ("  {0,-8} {1,-9} {2,-5} {3,-5}  {4}" -f $s.PID, $s.AgeStr, $s.Cmd, $s.Node, $s.Status)
    }
}
Write-Host ""

# Anomalies
$warnSessions = @($sessions | Where-Object { $_.Status -ne "OK" })
$allOk = ($warnSessions.Count -eq 0 -and $claudeStatus -eq "OK" -and $nodeStatus -eq "OK" -and $cmdStatus -eq "OK" -and $oldOrphanCmds.Count -eq 0)
Write-Host "--- ANOMALIES ---"
if ($allOk) {
    Write-Host "  None - system looks healthy."
} else {
    foreach ($s in $warnSessions) {
        Write-Host ("  PID {0}  ({1} old, {2} cmd, {3} node):  {4}" -f $s.PID, $s.AgeStr, $s.Cmd, $s.Node, $s.Status)
    }
    if ($claudeStatus -eq "WARN") { Write-Host ("  Total claude.exe ({0}) >= threshold ({1})" -f $totalClaude, $WARN_CLAUDE) }
    if ($cmdStatus    -eq "WARN") { Write-Host ("  Total cmd.exe ({0}) >= threshold ({1})" -f $totalCmd, $WARN_CMD) }
    if ($nodeStatus   -eq "WARN") { Write-Host ("  Total node.exe ({0}) >= threshold ({1})" -f $totalNode, $WARN_NODE) }
    foreach ($c in $oldOrphanCmds) {
        $ageH = [math]::Round(($now - $c.CreationDate).TotalHours, 1)
        Write-Host ("  cmd.exe PID {0}  (orphan, {1}h old - parent process gone)" -f $c.ProcessId, $ageH)
    }
}
Write-Host ""

# Snapshot history (optional: only shown if a snapshot log exists)
Write-Host "--- SNAPSHOT HISTORY (last 5 session starts) ---"
if (Test-Path $snapshotLog) {
    $lines = @(Get-Content $snapshotLog -ErrorAction SilentlyContinue | Select-Object -Last 5)
    if ($lines.Count -eq 0) {
        Write-Host "  Log exists but is empty."
    }
    foreach ($line in $lines) {
        try {
            $obj = $line | ConvertFrom-Json
            $sid = if ($obj.session.Length -gt 8) { $obj.session.Substring(0, 8) } else { $obj.session }
            Write-Host ("  {0}  session {1}  claude:{2}  cmd:{3}  node:{4}" -f $obj.ts, $sid, $obj.claude, $obj.cmd, $obj.node)
        } catch {
            Write-Host "  $line"
        }
    }
} else {
    Write-Host "  No history yet - log starts recording on next session start."
}
Write-Host ""

# Suggested actions
Write-Host "--- SUGGESTED ACTIONS ---"
Write-Host "  NOTE: Run these in elevated PowerShell or CMD - NOT in Git Bash."
Write-Host ""
if ($warnSessions.Count -gt 0) {
    Write-Host "  Kill specific sessions (and their full process trees):"
    foreach ($s in $warnSessions) {
        Write-Host ("  # PID {0}  (age {1}, {2} cmd, {3} node)" -f $s.PID, $s.AgeStr, $s.Cmd, $s.Node)
        Write-Host ("  taskkill /T /F /PID {0}" -f $s.PID)
        Write-Host ""
    }
}
if ($claudeStatus -eq "WARN" -or $nodeStatus -eq "WARN") {
    Write-Host "  Kill ALL claude sessions and their children:"
    Write-Host "  Get-Process claude -ErrorAction SilentlyContinue | ForEach-Object { taskkill /T /F /PID `$_.Id }"
    Write-Host ""
}
if ($oldOrphanCmds.Count -gt 0) {
    Write-Host "  Kill orphaned old cmd.exe processes:"
    foreach ($c in $oldOrphanCmds) {
        Write-Host ("  taskkill /F /PID {0}" -f $c.ProcessId)
    }
    Write-Host ""
}
if ($allOk) {
    Write-Host "  No action needed."
}
Write-Host $sep
Write-Host ""
