# Letterboxd-Stats

First, I'm not a developer; don't judge. More of a scripter, if anything.

I love movies though! And love checking my letterboxd stats. As a completionist I like to challenge myself to watch as many movies in the "prestigious" lists (IMDb Top 250, Edgar Wright's 1,000 Favorite Movies, etc) as I can! What I couldn't find was a good indication of what movies stretched across multiple lists, which do the most, and so forth, so I can get the most bang for my watch. So, I wrote this. It's simple, but it works.

## Update 24.1.3

Modified for when a list uses custom posters, the URL was returning blank and not matching with titles you've watched.

## Update 23.1.25

I added the ability to scan your watched movies using your username as seen in the letterboxd URLs.

Also prompts you to run specific reports once finished.

## Older methods of calling data

`$movieList.movie | group | sort count -Descending | select name, count` shows all unique movies and the count of how many lists they're in, highest at the top.

If you want to see the lists they're in you can use `$movieList.Where({$_.movie -eq "<movie to see>"}).list` (ie. `$movieList.Where({$_.movie -eq "Metropolis"}).list`).

```powershell
$movieList.Where({$_.movie -eq "Metropolis"}).list | sort
```
```
1,001 To See Before You Die
Edgar Wright's 1,000 Favorites
IMDb Top 250
Letterboxd Top 250
Sight & Sound Top 100
```

If you want to get a movie in the list at random:
```powershell
$movieList.movie | select -unique | Get-Random
```
```
Spider-Man 2
```

If you're having an issue running this script it may be that you're PC isn't setup for running PS scripts, you may need to Run as Admin and `Set-ExecutionPolicy` to `RemoteSigned` or `Unrestricted`.
