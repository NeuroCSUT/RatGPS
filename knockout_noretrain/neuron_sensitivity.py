
import numpy as np
import re

neurons = []

spikes = np.loadtxt("data/R2192_1x1400_at35_step200_bin100-RAW_feat.dat")
print spikes.shape
sp = spikes [::7,:]
print sp.shape
spikecounts = np.sum(sp, axis=0)
print spikecounts.shape, np.min(spikecounts), np.max(spikecounts)


for i in range(63):
  mean_e = []
  median_e = []
  for version in [6,7,8,9,10]:
	filename= "R2192_KO_"+str(i)+"/KO_"+str(i)+"_predictions_"+str(version)+".txt"
	f=open(filename,"r")
	lines = f.readlines()
	f.close()

    # the result avgd over fold is the last line in file
	numbers = re.findall("\d+\.\d+", lines[-1])
	print numbers
	mean_e.append(float(numbers[1]))
	median_e.append(float(numbers[-1]))
  print "Neuron nr "+str(i)+": mean:", np.mean(mean_e),"+-", np.std(mean_e),"        avg median:", np.mean(median_e), "+-" ,np.std(median_e)
  neurons.append([i, np.mean(mean_e), np.mean(median_e), spikecounts[i]])

print "shape", np.shape(neurons)
sorted_by_mean = sorted(neurons, key=lambda n: n[1])
sorted_by_median = sorted(neurons, key=lambda n: n[2])

for n in sorted_by_mean[::-1]:
	print n[3]
	#print "neuron ", n[0]," : ",n[1],",",n[2]

#print "MEAN:", sorted_by_mean[:5], "          ",sorted_by_mean[-5:]
#print "MEDIAN", sorted_by_median[:5], "          ",sorted_by_median[-5:]"""
