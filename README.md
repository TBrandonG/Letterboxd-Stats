# Letterboxd-Stats

First, I'm not a developer; don't judge. More of a scripter, if anything.

I love movies though! And love checking my letterboxd stats. As a completionist I like to challenge myself to watch as many movies in the "prestigious" lists (IMDb Top 250, Edgar Wright's 1,000 Favorite Movies, etc) as I can! What I couldn't find was a good indication of what movies stretched across multiple lists, which do the most, and so forth, so I can get the most bang for my watch. So, I wrote this. It's simple, but it works. Longest time is spent comparing each unique movie to all in the list to get a count, and I'm sure there's a better/faster way, but this worked for now.

`$finalMovieList | sort count -Descending` shows all unique movies and the count of how many lists they're in, highest at the top.

If you want to see the lists they're in you can use `$movieList.Where({$_.movie -eq "<movie to see>"}).list` (ie. `$movieList.Where({$_.movie -eq "Metropolis"}).list`).

```powershell
$movieList.Where({$_.movie -eq "Metropolis"}).list | sort
```
```
1,001 To See Before You Die
Edgar Wright's 1,000 Favorites
IMDb Top 250
IMDb Top 250
Letterboxd Top 250
Sight & Sound Top 100
```
