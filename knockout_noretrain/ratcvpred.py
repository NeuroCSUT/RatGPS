import numpy as np
import argparse
import math
import os.path
from ratlstm import *
from sklearn.cross_validation import KFold

def cvpredict(model, X, y, args):
  preds = []
  targets = []

  for i, (rest_idx, test_idx) in enumerate(KFold(X.shape[0], args.cvfolds)):
    test_X = X[test_idx]
    test_y = y[test_idx]
    print "test shape:", test_X.shape, test_y.shape

    test_X, test_y = sliding_window(test_X, test_y, args.seqlen)

    model_path = args.save_path + "-" + str(i + 1) + ".hdf5"
    pred_y = model.predict(test_X, model_path)
    preds.append(pred_y)
    targets.append(test_y)

  return np.concatenate(preds), np.concatenate(targets)

if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  add_data_params(parser)
  add_model_params(parser)
  parser.add_argument("save_path")
  parser.add_argument("preds_path")
  parser.add_argument("--cvfolds", type=int, default=10)
  parser.add_argument("--KO", type=int, default=-1) #extra argument to knock the s** out of a neuron 
  args = parser.parse_args()


  X, y = load_data(args.features, args.locations)
  
  #KNOCKOUT
  if args.KO > -1:
    X[:, args.KO]= 0
    print "removing data at line", args.KO
    
    if args.KO==0:
      np.savetxt("KO_neuron0_features.dat",X, fmt="%d")

  model = RatLSTM(**vars(args))

  input_size = X.shape[1]
  output_size = y.shape[1]
  model.init(input_size, output_size)


  preds, targets = cvpredict(model, X, y, args)
  print "preds shape:", preds.shape, "targets shape:", targets.shape
  np.savez_compressed(args.preds_path, preds=preds, targets=targets)
  print "mse = %g, mean dist = %g, median dist = %g" % (mse(preds, targets), mean_distance(preds, targets), median_distance(preds, targets))
