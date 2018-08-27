import numpy as np
import argparse
import math
import os.path
from ratlstm import *
from sklearn.cross_validation import KFold


def cv_activity(model, X, y, args):
  activations = []
  targets = []
  
  for i, (rest_idx, test_idx) in enumerate(KFold(X.shape[0], args.cvfolds)):
    test_X = X[test_idx]
    test_y = y[test_idx]
    print "test shape:", test_X.shape, test_y.shape

    test_X, test_y = sliding_window(test_X, test_y, args.seqlen)

    model_path = args.save_path + "-" + str(i + 1) + ".hdf5"
    activation = model.last_layer_activation(test_X, model_path)
    activations.append(activation)
    targets.append(test_y)

  return np.concatenate(activations), np.concatenate(targets)

if __name__ == '__main__':


  parser = argparse.ArgumentParser()
  add_data_params(parser)
  add_model_params(parser)
  parser.add_argument("save_path")
  parser.add_argument("activations_path")
  parser.add_argument("--cvfolds", type=int, default=10)
  args = parser.parse_args()

  X, y = load_data(args.features, args.locations)

  model = RatLSTM(**vars(args))


  input_size = X.shape[1]
  output_size = y.shape[1]
  model.init(input_size, output_size, gradients=False)


  print "Calculating gradients..."
  activations, targets = cv_activity(model, X, y, args)
  print "grads shape:", activations.shape, "targets shape:", targets.shape
  np.savez_compressed(args.activations_path+"_new", activations=activations, targets=targets)
  print "Saved activations and targets to", args.activations_path
