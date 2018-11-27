#Read_Bin_Data

Code specifically for reading in raw single unit data and then doing basic processing such as binning, position corrections and generating a ratemap. Analyses more sophisticated than these are dealt with by functions in other folders. Many of these core functions were originally written by Mike Anderson as part of mTint and have been modified over the years.


## Getting started
The Axona recording system (DACQ) saves several different files for each recording session, the core files being: xxxx.pos which describes the animals location in space, xxxx.eeg and .egf which stores the LFP (egf being higher bit rate), and files ending with numbers (e.g. xxx.1 being tetrode 1, xxx.2 being tetrode 2 etc) which are the spikes times and waveforms for action potentials from each tetrode. The function *read_DACQ.m* reads all these files into memory and stores them as a single matlab structure (see below for details). NB. *read_DACQ.m* calls many of the functions in this folder and essentially insulates the user from having to call them individually - though you can if you want more control.

The allocation of spikes to a specific cell (i.e. ‘cutting’ or ‘clustering’ the data) is done offline after the recording typically by a program such as Tint and may be manual or automatic (e.g. using KlustaKwik). The output of this process are .cut files which lists, for each tetrode, the allocation of each spike to a specific cell. For example xxxx_1.cut would be the cut file for tetrode 1. Cut files are loaded into memory by a second function *read_cut_file.m* which generates a column vector with a length equal to the number of spikes.

Finally the information from the cut file and raw DACQ data can be combined to generate a ratemap (the average firing rate of a given cell at different locations within the environment). This is done by the function *make_smooth_ratemap.m*.

So basic use is as follows:  
[ data ] = read_DACQ( pathFlnm, vars )  
pathFlnm is name and location of file to load e.g. 'd:\data\r123\234.set' but can be missed out. If pathFlnm is not specified the function will open a GUI to ask the user to select the file to load.  
vars, which also does not have to be specified, is a structure containing various data processing options (see specific function for more details). If vars isn't specified the function loads a set of default values from the function *default_read_vars.m*
So the easiest way to use read_DACQ would be as follows:  
[data]=read_DACQ();

Note the folder *example_data* contained within this folder includes some data that can be used to test these functions - see within that folder for further details.

Then to load the cut file - this is the allocation of each spike to a given cluster - you need to run 
exactCut=read_cut_file(pathFlnm);  
Where pathFlnm is the full path and filename of a cutfile (e.g. d:\data\r123\345_1.cut').
Note cut files are for a single tetrode - so might need to load multiple tetrodes if needed. To reiterate the contents of cut file is a list of numbers - the same length as there are spikes on that tetrode - giving the cluster assignment for each spike (0 being no assignment - note if the data was generated with KlustaKwik then 1 means no assignment).

To product a ratemap you now need to use *easy_make_ratemap.m* as follows:
smthRm =easy_make_ratemap( data, tet, cell, exactCut )
Where data is output of read_DACQ
tet is the number of the tetrode that we want to see the ratemap for
cell is the number of the cell that we want to see the ratemap for (i.e. its cluster number)
Finally exactCut - is the output of read_cut_file.m

As a final step you can view the ratemap using *image_rm.m* which will render the ratemap using the standard five colour scheme (from Tint). That is five colours indicate firing rate, the hotter colours (i.e. red) indicating higher rates, and colder (i.e. blue) lower rates. Each colour represents a band of rates that is 20% of the ‘width’ of the peak rate. The peak rate itself will be displayed in the title of the figure and unvisited bins will be marked with white. So type:
image_rm(smthRm)




## List of contents
Might not be complete

**EXAMPLE_DATA** A directory containing Axona recording data in a raw and processed form (as MAT files). Can be used for testing of the functions contained in this git repo.

**BIN_DATA** Bins spike and pos data into polar or spatial ratemaps
NB. This code is closely derived from mTint files of a similar name but
those files are now incomparable with use outside of mTint. Also note
this code previously called bin_pos_data but that function has now been
incorporated into this one. Binning is done by *histnd* which has also been
extensively rewritten for speed.Generally next step after binning by this function will be *make_smooth_ratemap.m* which smooths both dwell_time and spikes then
divides to get a ratemap. Note if using 'pxd' option then returned arrays
are already rates and will need to be smoothed which can also be done by
*make_smooth_ratemap.m*.

**CB_BIN_DATA*** Performs exactly the same function as bin_data and just passes 
variables through to that function - is included for back compatibility.


**HISTND** Bins columnar N dimensional data into an Nd array.
Primarily for binning spatial and/or directional data. Also used for pxd 
analysis which requires simultaneous binning of position and direction 
data.

**IMAGE_RM.M** Displays a ratemap using standard parameters (i.e. unvisited bins are marked in white, five colour levels are used to indicate firing rate (hot being the highest rate and cold the lowest), the peak rate of the cell’s firing is indicated in the title). For this function to run the function *tintColorMap* must be in the path as this specifies the colour levels of the tint colour map.

**MAKE_SMOOTH_RATEMAPS** Gets rate from spike & dwell  with smoothing
Takes binned pos and spikes to produce ratemap - works with either 2D
spatial data or 1D head direction data (in which case smoothing is done
in circular space with ends wrapping). Smoothing kernel can with either a
boxcar or gaussian (specified with 'boxcar' or 'guas'). 
NOTE SPECIAL CASE TO DEAL WTIH RATE. e.g. pxd code returns rate, it's not
possible to smooth dwell and spikes before dividing. To just apply the
standard smoothing to rate but still mark out unvisted bins with nans
supply the first variables (binPos) as a logical array of 1s for visited
bins and 0s for unvisted bins. e.g. if using bin_data with the 'pxd'
switch then the 3rd cell of the returned array is the binned pos map and
this can be used after doing logical on it. Then supply binSpk as the 
binned but unsmoothed ratemap (i.e. the 1st cell of the array returned by
bin_data. NB if using rate then only the first returned variable (smthRm) 
is meaningful.

**READ_DACQ.M** Reads in the raw Axona data and creates a single data structure containing all the basic information that is saved to disk by DACQ. The structure created is of the form: data.flnm (file name of data loaded); data.path (path of the data loaded); data.settings (setting pairs from the .set file); data.tetrode (waveform, spike times and matching pos points); data.pos (positional information, head speed, heading, xy); data.eeg (LFP data).

**READ_INP.M** Reads in the .inp file which DACQ generates to log events such as key presses and signals coming in through the DIO port (which is useful for syncing an external system such as VR with the recording system)

**READ_STM_FILE.M** Reads in the .stm file which DACQ uses to log stimulator events emitted by the DIO port and which are typically used to control a laser for opto studies. This code assumes a certain format for the .stm file (which is correct as of June17) but changes to the header file size, byte ordering, or level of precession might cause problems. Returns a list of times which should be the start times of stimulator events.

**TINTCOLORMAP.M** Just specifies the colour map that is used to turn firing rates into colours, is called by *image_rm.m* and duplicates the standard colour map used in Tint. Specifically five colours are used with each representing a 20% band of the peak rate of the cell. So for example if the peak rate were 10Hz then red is 8-10Hz, yellow is 6-8Hz, green 4-6Hz, light blue 2-4Hz and dark blue 0-2Hz.








