$movieList = @()

$letterboxdTop250 = @("Letterboxd Top 250","https://letterboxd.com/dave/list/official-top-250-narrative-feature-films/detail/page/")
$oscarBestPic = @("Oscar Best Picture Winners","https://letterboxd.com/jake_ziegler/list/academy-award-winners-for-best-picture/detail/page/")
$imdbTop250 = @("IMDb Top 250","https://letterboxd.com/dave/list/imdb-top-250/detail/page/")
$boxOfficeTop100 = @("Box Office Mojo All Time 100","https://letterboxd.com/matthew/list/box-office-mojo-all-time-worldwide/detail/page/")
$sightAndSount = @("Sight & Sound Top 100","https://letterboxd.com/bfi/list/sight-and-sounds-greatest-films-of-all-time/detail/page/")
$AFI100Years = @("AFI 100 Years 100 Movies","https://letterboxd.com/moseschan/list/afi-100-years-100-movies/detail/page/")
$Wrights1000Fav = @("Edgar Wright's 1,000 Favorites","https://letterboxd.com/crew/list/edgar-wrights-1000-favorite-movies/detail/page/")
$seeBeforeYouDie = @("1,001 To See Before You Die","https://letterboxd.com/gubarenko/list/1001-movies-you-must-see-before-you-die-2021/detail/page/")
$top250Docs = @("Top 250 Documentaries","https://letterboxd.com/jack/list/official-top-250-documentary-films/detail/page/")
$top250Horror = @("Top 250 Horror","https://letterboxd.com/darrencb/list/letterboxds-top-250-horror-films/detail/page/")
$top250WomenDirected = @("Top 250 Women-Directed","https://letterboxd.com/jack/list/women-directors-the-official-top-250-narrative/detail/page/")
$top100Animation = @("Top 100 Animation","https://letterboxd.com/lifeasfiction/list/letterboxd-100-animation/detail/page/")

$listArray = @($letterboxdTop250,$oscarBestPic,$imdbTop250,$boxOfficeTop100,$sightAndSount,$AFI100Years,$Wrights1000Fav,$seeBeforeYouDie,$top250Docs,$top250Horror,$top250WomenDirected,$top100Animation)

foreach($list in $listArray)
{
    $x = 1
    $listFound = $true
    $listMovies = @()
    while($listFound)
    {
        Write-Host -ForegroundColor White "Parsing $($list[0]), page $($x)"
        $WebResponse = Invoke-WebRequest "$($list[1])$($x)/"
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
                list = $list[0]
                movie = $movie
                order = $y
            }
            $movieList += $obj
            $y ++
         }
    }
}

$movieCounts = ($movieList.movie | group | sort count -Descending | select count, name).where({$_.count -gt 4})
