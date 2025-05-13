function Test-GitRepository($path) {
    return Test-Path (Join-Path $path ".git") -PathType Container
}

function Get-PreviousWorkingDay {
    $daysToSubtract = if ((Get-Date).DayOfWeek -eq 'Sunday') { 2 }
                      elseif ((Get-Date).DayOfWeek -eq 'Monday') { 3 }
                      else { 1 }
    return (Get-Date).AddDays(-$daysToSubtract).ToString("yyyy-MM-dd")
}

$currentGitUser = git config user.name
$yesterday = Get-PreviousWorkingDay
$repos = Get-ChildItem -Directory -Path "D:\repositories"

foreach ($repo in $repos) {
    if (Test-GitRepository $repo.FullName) {
        $yesterdayCommits = & git -C $repo.FullName log --all --author="$currentGitUser" --since="$yesterday 00:00:00" --until="$yesterday 23:59:59" --format="%s"
        
        if ($yesterdayCommits.Count) {
            Write-Host "`n>>>> $repo"
            $yesterdayCommits | ForEach-Object { Write-Host "- $_" }
        }
    }
}