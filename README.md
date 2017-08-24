# process_joysrad94_data

author: Nils Küchler

contact: tnomokon@uni-koeln.de

# what does the software?
the software reads data recorded with the FMCW-radar of RPG. RPG stores the data in binary format. the software converts it into netcdf4 format. additionally some reprocessing of the data can be applied including dealasing the radar spectra and the calculation of higher moments. the software can handle 3 different file formats. i) binary files created with RPG software version 1. ii) netcdf files created from i) where no additional processing has been applied. iii) binary files created with RPG software version 2. this software automatically identifies the file type and adjusts reprocessing automatically and creates a unified netcdf file for any of the file types i) to iii).

# description of main functions
## call_process_joyrad94_data.m:
main function contains descriptor file in which the level of reprocessing can be selected, e.g. if spectra should be dealiased or not, etc.

## process_joyrad94_data.m:
detetermines input file type and creates unified netcdf file.

if called: calculates higher spectral moments calling "radar_moments.m" and/or dealiases radar Doppler spectra calling "dealias_spectra.m"

## dealias_spectra.m
if terminal velocity of particles exceed the nyquist limit, then, in FMCW radar, their signal is folded into the upper and lower range gate. by concetenating adjacent spectra, the original spectrum can be recovered. the goodness of the dealiasing procedure is stored for each bin (see further description of variables in netcdf files, or write_joyrad94_data_2_nc)

## radar_moments.m:
calculates higher spectral moments by

i) determining the mean and peak noise level using Hildebran-Sekon procedure

ii) determining signficant signal as blocks with at least three consecutive bins above peak noise level. if a block is found it is extended by including all adjacent bins until the signal drops the first time below the mean noise level.

iii) the mean noise floor is subtracted from valid signal and spectral moments are calculated. note that all moments are calculated for the entire spectra and not just for the main peak

# IMPORTANT NOTE FOR DATA USERS
## signal contamination at certain IF frequencies
note that the radar pc, acquiring and processing the data produces a signal contamination at certain IF-bins during the first processing done by the RPG software. the contaminations are spikes in the Doppler spectra. they occur at certain IF frequencies which are induced by some oscillation in the radar PC hardware. for the "High Res" mode, the according range bins have the number 224, 225, 765 and 766. these artificial spikes are only filtered out if there is no cloud at that range. if there is cloud the spikes are visible in the spectra. usually the spikes do not cover more than two bins above peak noise level, however, occasionally they do. so be aware when analyzing the data.

## corrections for beam widh and gain


