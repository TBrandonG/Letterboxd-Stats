cls

$username = "b_bombr" #read-host "Enter your Letterboxd username as it appears in the URL."

### Parse your personal Letterboxd Stats page for the available lists and their respective URLs
$WebResponse = Invoke-WebRequest "https://letterboxd.com/$($username)/stats/"
$listNames = @(($WebResponse.ParsedHtml.getElementsByTagName('span') | where {$_.classname -eq "list-title yir-label"}).innerHTML.replace("<br>"," ").replace("&amp;","&"))
$listURLs = @($WebResponse.Links | where{$_.innerHTML -like "*list-progress-inner*"}).href
### Match lists with their respective URLs.
$listObj = for($i = 0; $i -lt $listNames.Count; $i++)
{
    Write-Verbose "$($listNames[$i]),$($listURLs[$i])"
    [PSCustomObject]@{
        name = $listNames[$i]
        link = "https://letterboxd.com/$($listURLs[$i])"
    }
}

### Loop through each list and collect movie titles and the respective URLs for each movie to alleviate issues with duplicate titles (ex. Dracula 1931 (/film/dracula/) vs. Dracula 1958 (/film/dracula-1958/))
$movieTable = @()
foreach($list in $listObj)
{
    $page = 1
    $listFound = $true
    $newlistMovies = @()
    while($listFound)
    {
        Write-Host -ForegroundColor White "Parsing $($list.name), page $($page)"
		## Get movie titles if available, if not end while loop, if yes get movie URLS
        $WebResponse = Invoke-WebRequest "$($list.link)page/$($page)/"
        $pageMovies = @($WebResponse.images | where {$_.class -eq "Image"}).alt
        if($pageMovies.count -eq 0)
        {
            $listFound = $false
        }
		else
		{
			## Get movie URLs and add data to obj with list title, URL, and position in the list
			$pageURLs = @($WebResponse.ParsedHtml.getElementsByTagName('li') | where {$_.classname -like "poster-container*"}).innerHTML | foreach{$_.Split('""')[9]}
			for($i = 0; $i -lt $pageMovies.count; $i++)
			{
				$obj = New-Object psobject -Property @{
					list = $list.name
					name = $pageMovies[$i]
					movieUrl = "https://letterboxd.com$($pageURLs[$i])"
					listUrl = $list.link
                    listPosition = ($page - 1) * 100 + $i + 1
				}
				$movieTable += $obj
			}
			$page ++
		}
    }
}

### Loop through each page of movies you're watched to collect their titles and URLs
$page = 1
$listFound = $true
$myMovies = @()
while($listFound)
{
    Write-Host -ForegroundColor White "Parsing my watched movies, page $($page)"
    $WebResponse = Invoke-WebRequest "https://letterboxd.com/$($username)/films/page/$($page)/"
    $pageMovies = @($WebResponse.images | where {$_.class -eq "Image"}).alt
    if($pageMovies.count -eq 0)
    {
        $listFound = $false
    }
	else
	{
		$pageURLs = @($WebResponse.ParsedHtml.getElementsByTagName('li') | where {$_.classname -like "poster-container*"}).innerHTML | foreach{$_.Split('""')[9]}
		for($i = 0; $i -lt $pageMovies.count; $i++)
		{
			$obj = New-Object psobject -Property @{
				name = $pageMovies[$i]
				URL = "https://letterboxd.com$($pageURLs[$i])"
			}
			$myMovies += $obj
		}
	}
    $page ++
}

## Pull the list of movie titles from IMDB Top 250 page, cause why not, but not reliable in comparing with Letterboxd list due to naming differences ("and" vs. "&" and others)
$WebResponse = Invoke-WebRequest "https://www.imdb.com/chart/top/?ref_=nv_mv_250"
$currentIMDB = ($WebResponse.Links.where({$_.innerHTML -eq $_.innerText -and $_.href -match "/title/"})).innerText

## Null out old variables
$null = $pageURLs,$pageMovies,$obj,$WebResponse,$listNames,$listURLs,$listObj,$username

## few reports to start with
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
        $movieTable
    }
    1 {
        $movieTable.Where({$_.movieUrl -notin $myMovies.URL})
    }
    2 {
        ($movieTable.movieUrl | group -Property name, movieURL | sort count -Descending | select name, count).where({$_.Count -gt 3})
    }
    3 {
        ($movieTable.Where({$_.movieUrl -notin $myMovies.URL}) | group -Property name, movieURL | sort count -Descending | select name, count).where({$_.Count -gt 3})
    }
}
