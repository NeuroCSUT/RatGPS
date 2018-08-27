import numpy as np
import argparse
import math
import os.path
from ratdata import *
from ratlstm import *

from sklearn.cross_validation import KFold

def cvfit(model, X, y, args):
  # remember initial weights
  weights = model.get_weights()
  results = []
  fold_counts = []

  for i, (rest_idx, test_idx) in enumerate(KFold(X.shape[0], args.cvfolds)):
    # in every cross validation fold, test_idx are all in one row (no shuffling)
    min_test_idx = np.min(test_idx)
    max_test_idx = np.max(test_idx)

    print "test size:", len(test_idx), "rest size:", len(rest_idx)

    # get test set
    # in here each row is still just one splike count vector
    test_X = X[test_idx]
    test_y = y[test_idx]

    # after this each element corresponds to a whole sequence of spike count vectors
    test_X, test_y = sliding_window(test_X, test_y, args.seqlen) 
    # done with test set


    # Test set cuts rest of the data into two pieces - before and after test set
    # first piece of "rest" comes from 0 till the beginning of test
    first_part_X = X[:min_test_idx,:]
    first_part_y = y[:min_test_idx,:]
      
    # second piece goes from the end of test till the end of data
    second_part_X = X[(max_test_idx+1):,:]
    second_part_y = y[(max_test_idx+1):,:]

    print "first part size:", first_part_X.shape[0], "second part size:", second_part_X.shape[0]

    if first_part_X.size > 0 and second_part_X.size > 0: #if both pieces exist (if test set is not the first nor last junk)
      # create temporal sequeces of spike count vectors for both pieces
      first_part_X, first_part_y = sliding_window(first_part_X, first_part_y, args.seqlen)
      second_part_X, second_part_y = sliding_window(second_part_X, second_part_y, args.seqlen)
      # merge the data
      rest_X = np.vstack((first_part_X,second_part_X))
      rest_y = np.vstack((first_part_y,second_part_y))

    elif first_part_X.size > 0: #if empty, then size is 0
      rest_X, rest_y = sliding_window(first_part_X, first_part_y, args.seqlen)
    elif second_part_X.size > 0: #if empty, then size is 0
      rest_X, rest_y = sliding_window(second_part_X, second_part_y, args.seqlen)
    else:
      assert False, "Size of both first and second part was zero, shouldn't happen."

    print "test shapes:", test_X.shape, test_y.shape, "rest shapes:", rest_X.shape, rest_y.shape

    if args.train_set == 1:  # no special validation set, using test set as validation
      valid_X, valid_y = (test_X, test_y)
      train_X, train_y = (rest_X, rest_y)
    else:  # in case we want to cut train_set int train and val sets
      train_X, train_y, valid_X, valid_y = split_data(rest_X, rest_y, args.train_set, args.split_shuffle)

    model_path = args.save_path + "-" + str(i + 1) + ".hdf5"
    model.set_weights(weights)

    model.fit(train_X, train_y, valid_X, valid_y, model_path)
    train_err, train_dist = model.eval(train_X, train_y, model_path)
    valid_err, valid_dist = model.eval(valid_X, valid_y, model_path)
    test_err, test_dist = model.eval(test_X, test_y, model_path)
    print 'train mse = %g, validation mse = %g, test mse = %g' % (train_err, valid_err, test_err)
    print 'train dist = %g, validation dist = %g, test dist = %g' % (train_dist, valid_dist, test_dist)
    results.append((train_dist, valid_dist, test_dist))
    fold_counts.append(len(test_idx))

  mean_dist = tuple(np.average(results, axis=0, weights=fold_counts))
  print "mean train dist = %g, mean valid dist = %g, mean test dist = %g" % mean_dist
  return mean_dist

if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  add_data_params(parser)
  add_model_params(parser)
  parser.add_argument("save_path")
  parser.add_argument("--cvfolds", type=int, default=10)
  parser.add_argument("--cut_first_secs", type=int, default=0)

  args = parser.parse_args()

  X, y = load_data(args.features, args.locations)
  print "original data dimensions from load_data", X.shape, y.shape

  # first seconds of the recording seem to have bad data
  if args.cut_first_secs>0:
    print "cutting first seconds to remove mistaken locations", np.shape(X), np.shape(y)
    X = X[args.cut_first_secs*5:,:]
    y = y[args.cut_first_secs*5:,:]
    print "After cutting first seconds to remove mistaken locations", np.shape(X), np.shape(y)

  model = RatLSTM(**vars(args))

  input_size = X.shape[1]
  output_size = y.shape[1]

  model.init(input_size, output_size)
  cvfit(model, X, y, args)
