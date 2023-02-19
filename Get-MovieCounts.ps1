cls

$movieList = @()
$username = read-host "Enter your Letterboxd username as it appears in the URL."
$WebResponse = Invoke-WebRequest "https://letterboxd.com/$($username)/stats/"
$listNames = @(($WebResponse.ParsedHtml.getElementsByTagName('span') | where {$_.classname -eq "list-title yir-label"}).innerHTML.replace("<br>"," ").replace("&amp;","&"))
$max = $listNames.Count
if($listLinks.count -gt $listNames.count)
{
    $max = $listLinks.Count
}

$listObj = for ( $i = 0; $i -lt $max; $i++)
{
    Write-Verbose "$($listNames[$i]),$($listLinks[$i])"
    [PSCustomObject]@{
        name = $listNames[$i]
        link = $listLinks[$i]
    }
}

foreach($list in $listObj)
{
    $x = 1
    $listFound = $true
    $listMovies = @()
    while($listFound)
    {
        Write-Host -ForegroundColor White "Parsing $($list.name), page $($x)"
        $WebResponse = Invoke-WebRequest "https://letterboxd.com/$($list.link)page/$($x)/"
        $listMovies += ($WebResponse.images | where {$_.class -eq "Image"}).alt
        if((($WebResponse.images | where {$_.class -eq "Image"}).alt).count -eq 0)
        {
            $listFound = $false
        }
        $x ++
    }
    $y = 1
    foreach($movie in $listMovies)
    {
        if(!($movie -eq "") -and !($movie -eq $null))
        {
            $obj = New-Object psobject -Property @{
                list = $list.name
                movie = $movie
                order = $y
                url = $list.link
            }
            $movieList += $obj
            $y ++
         }
    }
}

$x = 1
$listFound = $true
$myMovies = @()
while($listFound)
{
    Write-Host -ForegroundColor White "Parsing my watched movies, page $($x)"
    $WebResponse = Invoke-WebRequest "https://letterboxd.com/$($username)/films/page/$($x)/"
    $myMovies += ($WebResponse.images | where {$_.class -eq "Image"}).alt
    if((($WebResponse.images | where {$_.class -eq "Image"}).alt).count -eq 0)
    {
        $listFound = $false
    }
    $x ++
}
$watchedMovies = @()
foreach($movie in $myMovies)
{
    if(!($movie -eq "") -and !($movie -eq $null))
    {
        $obj = New-Object psobject -Property @{
            movie = $movie
        }
        $watchedMovies += $obj
        $y ++
    }
}

$listCounts = @()
foreach($list in $listObj.name)
{
    
     $obj = New-Object psobject -Property @{
        list = $list
        count = $movieList.where({$_.list -eq $list}).count
     }
     $listCounts += $obj
}

$WebResponse = Invoke-WebRequest "https://www.imdb.com/chart/top/?ref_=nv_mv_250"
$currentIMDB = ($WebResponse.Links.where({$_.innerHTML -eq $_.innerText -and $_.href -match "/title/"})).innerText

#$movieCounts = $movieList.movie | group | sort count -Descending | select name, count
$title = "Reports"
$message = "Select a report from the options below that you'd like to run."
$1 = New-Object System.Management.Automation.Host.ChoiceDescription "&1 - View entire table of lists and movies.",`
    "Eentire table of lists and movies."
$2 = New-Object System.Management.Automation.Host.ChoiceDescription "&2 - View entire table of lists and movies BUT removes movies you've watched.",`
    "Entire table of lists and movies BUT removes movies you've watched."
$3 = New-Object System.Management.Automation.Host.ChoiceDescription "&3 - Grouped table of movies and count of lists they're on.",`
    "Grouped table of movies and count of lists they're on."
$4 = New-Object System.Management.Automation.Host.ChoiceDescription "&4 - Grouped table of movies and count of lists they're on BUT removes movies you've watched.",`
    "Grouped table of movies and count of lists they're on BUT removes movies you've watched."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($1, $2, $3, $4)
$result = $host.ui.PromptForChoice($title,$message,$options,0)
switch($result) {
    0 {
        $movieList
    }
    1 {
        $movieList.Where({$_.movie -notin $watchedMovies.movie})
    }
    2 {
        $movieList.movie | group | sort count -Descending | select name, count
    }
    3 {
        ($movieList.Where({$_.movie -notin $watchedMovies.movie})).movie | group | sort count -Descending | select name, count
    }
}
