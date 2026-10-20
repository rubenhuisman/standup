function Get-PreviousWorkingDay {
    $daysToSubtract = if ((Get-Date).DayOfWeek -eq 'Sunday') { 2 }
                      elseif ((Get-Date).DayOfWeek -eq 'Monday') { 3 }
                      else { 1 }
    return (Get-Date).AddDays(-$daysToSubtract).ToString("yyyy-MM-dd")
}

$currentGitUser = git config user.name
$yesterday = Get-PreviousWorkingDay
$repos = Get-ChildItem -Directory -Path "D:\repositories" | Where-Object { Test-Path (Join-Path $_.FullName ".git") -PathType Container }

# run git log for all repos in parallel, git process startup dominates the runtime on Windows
$pool = [runspacefactory]::CreateRunspacePool(1, [Environment]::ProcessorCount * 2)
$pool.Open()

$jobs = foreach ($repo in $repos) {
    $ps = [powershell]::Create().AddScript({
        param($path, $author, $day)
        & git -C $path log --branches --remotes --author="$author" --since="$day 00:00:00" --until="$day 23:59:59" --format="%s"
    }).AddArgument($repo.FullName).AddArgument($currentGitUser).AddArgument($yesterday)
    $ps.RunspacePool = $pool
    [pscustomobject]@{ Repo = $repo; PS = $ps; Handle = $ps.BeginInvoke() }
}

foreach ($job in $jobs) {
    $yesterdayCommits = $job.PS.EndInvoke($job.Handle)
    $job.PS.Dispose()

    if ($yesterdayCommits.Count) {
        Write-Host "`n>>>> $($job.Repo)"
        $yesterdayCommits | ForEach-Object { Write-Host "- $_" }
    }
}

$pool.Close()
