Example_Data
=============

Several sets of single unit data (recorded using Axona system) which can be used to test the basic read in functions as well as functions for making rate maps etc.


**gridCell1838_t2c3_14-12-10.mat**
Data which has already been loaded into matlab (and partially processed) using read_DACQ.m which in turn calls the function in DACQ_core_functions. This animal had a grid cell on tetrode 2, cell 3. Loading the MAT into matlab will create four variables in the workspace. These are as follows:

1) data - this is the main data structure which is the basic read in functions create in matlab when loading Axona data. The data structure contains information about the animal’s movements (data.pos), action potentials and spike times (data.tetrode), and LFP (data.eeg)

2) exactCut - this is created by read_cut_file.m and is the contents of a single .cut file (as saved by Tint). exactCut specifies for each action potential recorded on a specific tetrode (this one is for tetrode 2) the cell that it is assigned to (where cell 0 is the junk cluster - note for data clustered using KlusterKwik cell 1 is the junk cluster). In this data cell 3 is a grid cell.

3) smthRm - is a smoothed ratemap created using make_smooth_ratemap.m (or its precursor) for the grid cell which is cell 3 on tetrode 2.

4) spikePosSamp - is for each of the action potentials that belong to cell 3 on tetrode 2 the matching pos sample (i.e. index into data.pos.xy)




**r1838_10-12-14** Folder containing data recorded by CB on 10/12/14 from r1838 using an Axona recording system. This data can be read into generate the standard data structure (ie. data.pos etc and data.tetrode etc) using the read_DACQ.m function (will in turn calls many of the functions in the DACQ_core_functions folder).

In brief this animal had 8 tetrodes, the first 4 in MEC and the second 4 in HPC. The folder contains cut files (xxx.cut) for each of these tetrodes, the raw spike data (files ending in a number from 1 to 8), LFP data from 3 electrodes (save at 250Hz in the eeg files and 4.8kHz in the egf files), position data (in .pos) and basic settings info (in .set).

This animal has a number of grid cells specified by the following tetrode cell pairs (i.e. first number is tetrode and second is cell): 11, 13, 21, 22, 23, 26, 28, 44 


