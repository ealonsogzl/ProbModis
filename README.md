# ProbModis
Probability of Snow Presence inside partially snow covered pixels of MODIS from Sentinel observations in mountain areas. 
## Overview
ProbModis is simple colleciton of functions to compute the probability of snow occurrence inside partially snow covered MODIS pixels from Sentintel 2 snow observations, ultimately aiming to map snow occurrence at 20 m spatial resolution in dates without Sentinel acquisition. 
## Details
Since early XXI century, MODIS sensors have allowed retrieving snow distribution in remote areas in a nearly daily basis, when these zones are no affected by cloud presence. Nonetheless, in heterogeneous mountain areas the spatial resolution of these observations (500m) is not high enough to observe different processes in which the snow has a determinant role. 
In the last 5 years, Sentinel 2 products allow to observe snow presence with a more detailed spatial resolution (20 m). This package achieves the same spatial resolution of Sentinel 2 snow products for MODIS snow observations. Hereby it allows obtaining detailed cartographies of snow presence from MODIS acquisitions when there are not available Sentinel observations comprising both, past years (before Sentintel 2 launch) and dates since 2015 without Sentinel acquisition. 
    • This package relies in the strong control that topographical characteristics have in snowpack distribution, which originates repeated snow distribution patterns in mountain areas mainly during melting period.
    • PROBMODIS computes the probability of having snow covered Sentinel-2 pixel (20 m x 20) when MODIS pixels (500 m x 500 m) are partially snow covered. 
    • This probability is computed for all dates having concurrent Sentintel 2 and MODIS acquisitions in which these conditions are satisfied; no cloud presence inside MODIS pixels (neither in Sentinel-2 pixels), only a 20 % of the study area is affected by cloud presence and the snow covered fraction of MODIS pixels is comprised between 0.1 and 0.9.
    • The package has been designed to introduce a shapefile of the study area and download both MODIS and Sentinel-2 images for dates with simultaneous acquisition with cloud presence under 20% and compute the probability of snow occurrence inside MODIS pixels. 
    Once ProbModis is computed for a specific study area, the snow covered fraction of MODIS pixels (500 m x 500 m) are easily transformed to presence/absence cartographies of snow at 20 x 20 m spatial resolution. 
## Installation
The package uses the Rspatial/terra library. See  [Rspatial/terra](https://github.com/rspatial/terra) for details
### Linux
```
remotes::install_github("rspatial/terra")
```
### Windows
The package is not tested yet in Windows, but it should work..
### Notes
ProbModis uses the Theia-snow cover products. Study areas out of [its boundaries](https://umap.openstreetmap.fr/fr/map/theias-sentinel-2-snow-tiles_156646#3/27.68/35.68) are not supported.
