# How to run Bayesian Code

**prerequisite**: Download data as instructed in the `../Data` folder
1) Launch MatLab in this folder
2) Add this folder and its subfolders to PATH in MatLab
3) Change "dataDir" variable to in the scripts `main\_testOnEstoniaData.m` (line 22) and `main\_testOnEstoniaData\_downsamp.m` (line 25)
4) In your MatLab CommandWindow launch `main_testOnEstoniaData`. As it gives many outputs, you should probably do:<\br>
`[bestMean, bestMedian, tWin2Test, meanErr, medianErr, animalStruct]=main_testOnEstoniaData`
5) By default, this will train MLE model on 2D data, for Bayesian with Memory and for using 1D-track data see the instructions below.

**To train Bayesian with Memory (instead of MLE), you need to**
1) Uncomment line 237 in `decode_crunchDataRaulVariant.m` and comment out line 238. 

**To train on 1D track (Z-maze) data, you need to:**
1) Comment out the part of `main\_testOnEstoniaData.m` that defines 2D data location (lines 29-36) and uncomment the part defining 1D data (lines 45-60)
2) In `decode_crunchDataRaulVariant.m` change the "truncS" variable to 25 (uncomment the line 113). This throws away first 25 second of recording, because the animal was not yet in the maze.
3) If using Bayesian with Memory, to get results similar to what was reported in the article, set "nStepForVel"=15 (line 74) to and "speedScaleFact"=5 (line 81) in `decode_calcBayesPost`

---

To run the downsampling experiment (Figure 2b in the article), run `[allMeanErr, allMedianErr] = main_testOnEstoniaData_downsamp` in MatLab Command Window.
