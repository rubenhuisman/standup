function Test-GitRepository {
    param (
        [string]$path
    )
    
    if (Test-Path (Join-Path $path ".git") -PathType Container) {
        return $true
    } else {
        return $false
    }
}

function Get-PreviousWorkingDay {
    $currentDate = Get-Date
    $dayOfWeek = $currentDate.DayOfWeek.value__
        
    if ($dayOfWeek -eq 0) {
        $previousWorkingDay = $currentDate.AddDays(-2)
    }    
    elseif ($dayOfWeek -eq 1) {
        $previousWorkingDay = $currentDate.AddDays(-3)
    }    
    else {
        $previousWorkingDay = $currentDate.AddDays(-1)
    }

    return $previousWorkingDay
}

$currentGitUser = git config user.name
$yesterday = (Get-PreviousWorkingDay).ToString("yyyy-MM-dd")
$repos = Get-ChildItem -Directory -Path "D:\repositories"

foreach ($repo in $repos) {
    if (Test-GitRepository -path $repo.FullName) {
          $yesterdayCommits = & git --git-dir="$($repo.FullName)\.git" log --author="$currentGitUser" --since="$yesterday 00:00:00" --until="$yesterday 23:59:59" --format="%s"

        if($yesterdayCommits.Count -gt 0) {
            Write-Host ""
            Write-Host ">>>> $repo"
        }
        
        foreach ($commit in $yesterdayCommits) {
            Write-Host "- $commit"
        }
    }
}