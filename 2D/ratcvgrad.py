import numpy as np
import argparse
import math
import os.path
from ratlstm import *
from ratdata import *
from sklearn.cross_validation import KFold

def cvgrads(model, X, y, args):
  grads = []
  targets = []
  
  for i, (rest_idx, test_idx) in enumerate(KFold(X.shape[0], args.cvfolds)):
    test_X = X[test_idx]
    test_y = y[test_idx]
    print "test shape:", test_X.shape, test_y.shape

    test_X, test_y = sliding_window(test_X, test_y, args.seqlen)

    model_path = args.save_path + "-" + str(i + 1) + ".hdf5"
    grad = model.gradients(test_X, test_y, model_path)
    grads.append(grad)
    targets.append(test_y)

  return np.concatenate(grads), np.concatenate(targets)

if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  add_data_params(parser)
  add_model_params(parser)
  parser.add_argument("save_path")
  parser.add_argument("grads_path")
  parser.add_argument("--cvfolds", type=int, default=5)
  args = parser.parse_args()

  X, y = load_data(args.features, args.locations)

  model = RatLSTM(**vars(args))

  input_size = X.shape[1]
  output_size = y.shape[1]
  # we set "gradients=True" to create also the part of graph returning grads
  model.init(input_size, output_size, gradients=True)


  print "Calculating gradients..."
  grads, targets = cvgrads(model, X, y, args)
  print "grads shape:", grads.shape, "targets shape:", targets.shape
  np.savez_compressed(args.grads_path, grads=grads, targets=targets)
  print "Saved gradients and targets to", args.grads_path
