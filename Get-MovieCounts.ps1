cls

$username = read-host "Enter your Letterboxd username as it appears in the URL."

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
			## Get 11th field too since Letterboxd wants to add lists that contain custom posters..
			$pageURLs2 = @($WebResponse.ParsedHtml.getElementsByTagName('li') | where {$_.classname -like "poster-container*"}).innerHTML | foreach{$_.Split('""')[11]}
			for($i = 0; $i -lt $pageMovies.count; $i++)
			{
				if($pageURLs[$i] -eq "")
				{
					$pageURLValue = $pageURLs2[$i]
				}
				else
				{
					$pageURLValue = $pageURLs[$i]
				}
				$obj = New-Object psobject -Property @{
					list = $list.name
					name = $pageMovies[$i]
					movieUrl = "https://letterboxd.com$($pageURLValue)"
					listUrl = $list.link
					listPosition = ($page - 1) * 100 + $i + 1
				}
				$movieTable += $obj
			}
			$page ++
		}
	}
}

### Loop through each page of movies you've watched to collect their titles and URLs
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

$newMovieTable = @()
$perc = $movieTable | group -Property list | select @{L = 'List'; E = {$_.Name}}, @{L = 'Count';E = {$_.Count}}, @{L = 'Percentage'; E = {1 / $_.Count}}
foreach($movie in $movieTable)
{
	$obj = New-Object psobject -Property @{
		name = $movie.name
		movieUrl = $movie.movieUrl
		listPosition = $movie.listPosition
		list = $movie.list
		listUrl = $movie.listUrl
		moviePercentage = ($perc | where {$_.List -eq $movie.List}).Percentage
	}
	$newMovieTable += $obj
}
$movieTable = $newMovieTable

$countTable = $movieTable | group -Property name, movieURL | sort count -Descending | select name, count
$wholeTable = @()
$c = 1
foreach($movie in $countTable)
{
	$loopMovieName = ($movie.name -split ", https")[0]
	$loopMovieURL = "https"+$(($movie.name -split ", https")[1])
	$percComplete = $c / $countTable.count * 100
	write-progress -Activity "Calculating for movie $($c) of $($countTable.count) - $loopMovieName" -PercentComplete $percComplete
	$obj = New-Object psobject -Property @{
		name = $loopMovieName
		count = $movie.count
		url = ($movieTable | Where {"$($_.name), $($_.movieUrl)" -eq $movie.name}).movieUrl | select -Unique
		percentage = [math]::Round(((($movieTable | Where {$_.name -eq $loopMovieName -and $_.movieUrl -eq $loopMovieURL}).moviePercentage | Measure-Object -sum).sum * 100),3)
	}
	$wholeTable += $obj
	$c ++
}

$null = $pageURLs,$pageMovies,$obj,$WebResponse,$listNames,$listURLs,$listObj,$username,$newMovieTable,$count

## few reports to start with
$title = "Reports"
$message = "Select a report."
$1 = New-Object System.Management.Automation.Host.ChoiceDescription "&1 - View entire table.",`
	"View entire table."
$2 = New-Object System.Management.Automation.Host.ChoiceDescription "&2 - View table, remove watched.",`
	"View table, remove watched."
$3 = New-Object System.Management.Automation.Host.ChoiceDescription "&3 - Table of movies with count.",`
	"Table of movies with count."
$4 = New-Object System.Management.Automation.Host.ChoiceDescription "&4 - Table of movies with count, remove watched.",`
	"Table of movies with count, remove watched."
$5 = New-Object System.Management.Automation.Host.ChoiceDescription "&5 - Table of movies with percentages, remove watched.",`
	"Table of movies with percentages, remove watched."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($1, $2, $3, $4, $5)
$result = $host.ui.PromptForChoice($title,$message,$options,0)
switch($result) {
	0 {
		$movieTable
	}
	1 {
		$movieTable.Where({$_.movieUrl -notin $myMovies.URL})
	}
	2 {
		$wholeTable | sort count -Descending | select name, count -First 10
	}
	3 {
		$wholeTable.Where({$_.url -notin $myMovies.URL}) | sort count -Descending | select name, count -First 10
	}
	4 {
		$wholeTable | where({$_.url -notin $myMovies.URL}) | sort percentage,count -descending | select name, url, percentage, count -first 20
	}
}
