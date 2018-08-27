import argparse
import numpy as np
import matplotlib.pyplot as plt
from ratdata import *

parser = argparse.ArgumentParser()
add_data_params(parser)
parser.add_argument("grads_path")
parser.add_argument("save_path")
parser.add_argument("--dpi", type = int, default = 80)
args = parser.parse_args()

data = np.load(args.grads_path)
grads = data['grads']
targets = data['targets']
print "grads:", grads.shape, "targets:", targets.shape

X, y = load_data(args.features, args.locations)

# plot feature importance
neuron_grads = np.mean(np.abs(grads), axis=(0,1))
feature_importance = neuron_grads
# make importances relative to max importance
feature_importance = 100.0 * (feature_importance / feature_importance.max())
sorted_idx = np.argsort(feature_importance)
pos = np.arange(sorted_idx.shape[0]) + .5
plt.figure(figsize=(9,15))
plt.barh(pos, feature_importance[sorted_idx], align="center")
plt.yticks(pos, sorted_idx)
plt.xlabel('Relative Importance')
plt.title('Variable Importance')
plt.savefig(args.save_path + "_feature_importance.png", dpi = args.dpi)

# activity of the most important neurons
plt.figure(figsize=(16,16))
for i in xrange(1,7):
    plt.subplot(3,2,i)
    plt.hexbin(y[...,0], y[...,1], X[...,sorted_idx[-i]], gridsize = 10)
    plt.colorbar()
    plt.title("Neuron #%d" % sorted_idx[-i])
plt.savefig(args.save_path + "_placefields_most_important.png", dpi = args.dpi)

# activity of the least important neurons
plt.figure(figsize=(16,16))
for i in xrange(1,7):
    plt.subplot(3,2,i)
    plt.hexbin(y[...,0], y[...,1], X[...,sorted_idx[i-1]], gridsize = 10)
    plt.colorbar()
    plt.title("Neuron #%d" % sorted_idx[i-1])
plt.savefig(args.save_path + "_placefields_least_important.png", dpi = args.dpi)

# importance of timesteps
timestep_grads = np.mean(np.abs(grads), axis=(0,2))
plt.figure(figsize=(12,9))
plt.plot(timestep_grads);
plt.savefig(args.save_path + "_timesteps.png", dpi = args.dpi)

# L1 normalized
normed_grads1 = grads / np.linalg.norm(grads, ord=1, axis=2, keepdims=True)
normed_timestep_grads1 = np.mean(np.abs(normed_grads1), axis=(0,2))
plt.figure(figsize=(12,9))
plt.plot(normed_timestep_grads1);
plt.savefig(args.save_path + "_timesteps_L1.png", dpi = args.dpi)

# L2 normalized
normed_grads2 = grads / np.linalg.norm(grads, ord=2, axis=2, keepdims=True)
normed_timestep_grads2 = np.mean(normed_grads2**2, axis=(0,2))
plt.figure(figsize=(12,9))
plt.plot(normed_timestep_grads2);
plt.savefig(args.save_path + "_timesteps_L2.png", dpi = args.dpi)

# importance of neurons on timesteps
neuron_timestep_grads = np.mean(np.abs(grads), axis=0)
plt.figure(figsize=(12,9))
plt.plot(neuron_timestep_grads);
plt.savefig(args.save_path + "_neuron_timesteps.png", dpi = args.dpi)

# L1 normalized
normed_neuron_timestep_grads1 = np.mean(np.abs(normed_grads1), axis=0)
plt.figure(figsize=(12,9))
plt.plot(normed_neuron_timestep_grads1);
plt.savefig(args.save_path + "_neuron_timesteps_L1.png", dpi = args.dpi)

# L2 normalized
normed_neuron_timestep_grads2 = np.mean(normed_grads2**2, axis=0)
plt.figure(figsize=(12,9))
plt.plot(normed_neuron_timestep_grads2);
plt.savefig(args.save_path + "_neuron_timesteps_L2.png", dpi = args.dpi)

# temporal importance curves of most important neurons
rows = 3
cols = 3
maxy = np.max(neuron_timestep_grads)
plt.figure(figsize=(12,9))
for i in xrange(1, rows * cols + 1):
    plt.subplot(rows, cols, i)
    plt.plot(neuron_timestep_grads[:, sorted_idx[-i]])
    plt.title("Neuron #" + str(sorted_idx[-i]))
    plt.ylim([0, maxy])
plt.tight_layout()
plt.savefig(args.save_path + "_neuron_timesteps_most_important.png", dpi = args.dpi)

# temporal importance curves of least important neurons
rows = 3
cols = 3
maxy = np.max(neuron_timestep_grads)
plt.figure(figsize=(12,9))
for i in xrange(1, rows * cols + 1):
    plt.subplot(rows, cols, i)
    plt.plot(neuron_timestep_grads[:, sorted_idx[i-1]])
    plt.title("Neuron #" + str(sorted_idx[i-1]))
    plt.ylim([0, maxy])
plt.tight_layout()
plt.savefig(args.save_path + "_neuron_timesteps_least_important.png", dpi = args.dpi)

# temporal importance curves of most important neurons
rows = 3
cols = 3
maxy = np.max(normed_neuron_timestep_grads1)
plt.figure(figsize=(12,9))
for i in xrange(1, rows * cols + 1):
    plt.subplot(rows, cols, i)
    plt.plot(normed_neuron_timestep_grads1[:, sorted_idx[-i]])
    plt.title("Neuron #" + str(sorted_idx[-i]))
    plt.ylim([0, maxy])
plt.tight_layout()
plt.savefig(args.save_path + "_neuron_timesteps_most_important_L1.png", dpi = args.dpi)

# temporal importance curves of least important neurons
rows = 3
cols = 3
maxy = np.max(normed_neuron_timestep_grads1)
plt.figure(figsize=(12,9))
for i in xrange(1, rows * cols + 1):
    plt.subplot(rows, cols, i)
    plt.plot(normed_neuron_timestep_grads1[:, sorted_idx[i-1]])
    plt.title("Neuron #" + str(sorted_idx[i-1]))
    plt.ylim([0, maxy])
plt.tight_layout()
plt.savefig(args.save_path + "_neuron_timesteps_least_important_L1.png", dpi = args.dpi)

# temporal importance curves of most important neurons
rows = 3
cols = 3
maxy = np.max(normed_neuron_timestep_grads2)
plt.figure(figsize=(12,9))
for i in xrange(1, rows * cols + 1):
    plt.subplot(rows, cols, i)
    plt.plot(normed_neuron_timestep_grads2[:, sorted_idx[-i]])
    plt.title("Neuron #" + str(sorted_idx[-i]))
    plt.ylim([0, maxy])
plt.tight_layout()
plt.savefig(args.save_path + "_neuron_timesteps_most_important_L2.png", dpi = args.dpi)

# temporal importance curves of least important neurons
rows = 3
cols = 3
maxy = np.max(normed_neuron_timestep_grads2)
plt.figure(figsize=(12,9))
for i in xrange(1, rows * cols + 1):
    plt.subplot(rows, cols, i)
    plt.plot(normed_neuron_timestep_grads2[:, sorted_idx[i-1]])
    plt.title("Neuron #" + str(sorted_idx[i-1]))
    plt.ylim([0, maxy])
plt.tight_layout()
plt.savefig(args.save_path + "_neuron_timesteps_least_important_L2.png", dpi = args.dpi)

# arena coverage
split = int(y.shape[0] * args.train_set)
plt.figure(figsize=(20,9))
plt.subplot(1,2,1)
plt.plot(y[:split,0], y[:split,1]);
plt.title("Training set")
plt.subplot(1,2,2)
plt.plot(y[split:,0], y[split:,1]);
plt.title("Validation set")
plt.savefig(args.save_path + "_arena_coverage.png", dpi = args.dpi)

print "Done"
