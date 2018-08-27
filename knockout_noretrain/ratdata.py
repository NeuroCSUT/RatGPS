import argparse
from scipy.io import loadmat
import numpy as np


# simply read in the data, depending on data type
def load_data(features, locations):
  if features.endswith(".mat"):
    X = loadmat(features)
    X = X['mm'].T
  elif features.endswith(".dat"):
    X = np.loadtxt(features)
  elif features.endswith(".npy"):
    X = np.load(features)
  else:
    assert False, "Unknown feature file format"

  if locations.endswith(".mat"):
    y = loadmat(locations)
    y = y['loc'] / 3.5 #given in pixels, not in cm
  elif locations.endswith(".dat"):
    y = np.loadtxt(locations)
  elif locations.endswith(".npy"):
    y = np.load(locations)
  else:
    assert False, "Unknown location file format"

  print "Original data:", X.shape, y.shape
  assert X.shape[0] == y.shape[0], "Number of samples in features and locations does not match"

  print "minX/maxX/meanX/stdX/miny/maxy:", np.min(X), np.max(X), np.mean(X), np.std(X), np.min(y), np.max(y)

  if y.ndim == 1:
    y = y[:,np.newaxis]
    print "position is 1D, changed shape to:", y.shape

  return (X, y)

# this function puts the consecutive data points into sequences
def reshape_data(X, y, seqlen):
  assert X.shape[0] == y.shape[0]
  nsamples = X.shape[0]
  nsamples = int(nsamples / seqlen) * seqlen

  # truncate remaining samples, if not divisible by sequence length
  X = X[:nsamples]
  y = y[:nsamples]

  nb_inputs = X.shape[1]
  nb_outputs = y.shape[1]

  X = np.reshape(X, (-1, seqlen, nb_inputs))
  y = np.reshape(y, (-1, seqlen, nb_outputs))

  print "After reshaping: ", X.shape, y.shape
  return (X, y)


def split_data(X, y, train_set, shuffle):
  assert X.shape[0] == y.shape[0]
  nsamples = X.shape[0]

  if 0 <= train_set <= 1:
    ntrain = int(nsamples * train_set)
    nvalid = nsamples - ntrain
  else:
    ntrain = int(train_set)
    nvalid = nsamples - ntrain

  #shuffle does not make sense for RNN that needs sequential data points as input
  if shuffle:
    print "WARNING: you should not be suffling the data points before splitting them into folds"
    train_idx = np.random.choice(range(nsamples), ntrain, replace=False)
    valid_idx = np.setdiff1d(range(nsamples), train_idx)
  else:
    train_idx = range(ntrain)
    valid_idx = range(ntrain, ntrain + nvalid)


  train_X = X[train_idx]
  train_y = y[train_idx]
  valid_X = X[valid_idx]
  valid_y = y[valid_idx]

  print "After splitting: ", train_X.shape, train_y.shape, valid_X.shape, valid_y.shape
  return (train_X, train_y, valid_X, valid_y)

def sliding_window(X, y, seqlen):
  # X - matrix where each row corresponds to a spike count vector of length nr_of_neurons
  # y - rat poisitions at the center of those spike count windows
  # seqlen - length of sequences we want to get out of this function

  Xs = []
  for i in xrange(seqlen): 
    if seqlen - i - 1 > 0:
      #take slices from 0 to -99, 1 to -98, ...,  98 to -1. 
      Xs.append(X[i:-(seqlen-i-1), np.newaxis, ...])
    else:  # cannot ask X[99:-0], so special case goes here
      print "last piece to add"
      Xs.append(X[i:, np.newaxis, ...])

  # we have seqlen(=100) slices each shifted in time. join them to get sequences of len 100
  X = np.concatenate(Xs, axis=1)
  y = y[seqlen-1:] # the poisitions are taken at the last timestep (from 99 to end) 
  print "After sliding window:", X.shape, y.shape

  return X, y


def split_transform(X, y, args):
  # split before sliding window, otherwise there would be too much overlap between train and test data
  train_X, train_y, valid_X, valid_y = split_data(X, y, args.train_set, False)
  train_X, train_y = sliding_window(train_X, train_y, args.seqlen)
  valid_X, valid_y = sliding_window(valid_X, valid_y, args.seqlen)
  return train_X, train_y, valid_X, valid_y


def str2bool(v):
  return v.lower() in ("yes", "true", "t", "1")

def add_data_params(parser):
  parser.add_argument("--features", default="data/R2192_1x1400_at35_step200_bin100-RAW_feat.dat")
  parser.add_argument("--locations", default="data/R2192_1x1400_at35_step200_bin100-RAW_pos.dat")
  parser.add_argument("--train_set", type=float, default=1)
  parser.add_argument("--seqlen", type=int, default=100)


if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  add_data_params(parser)
  args = parser.parse_args()

  #X, y = load_data(args.features, args.locations)
  #train_X, train_y, valid_X, valid_y = split_transform(X, y, args)
