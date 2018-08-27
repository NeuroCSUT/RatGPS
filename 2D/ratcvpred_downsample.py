import numpy as np
import argparse
import math
import os.path
from ratlstm import *
from ratbilstm import *
from ratFF import *
from sklearn.cross_validation import KFold

def cvpredict(model, X, y, args):
  preds = []
  targets = []

  if not args.sliding_window and args.model != "FF":
    # reshape before splitting to loose minimum amount of data
    X, y = reshape_data(X, y, args.seqlen)
  
  for i, (rest_idx, test_idx) in enumerate(KFold(X.shape[0], args.cvfolds)):
    test_X = X[test_idx]
    test_y = y[test_idx]
    print "test shape:", test_X.shape, test_y.shape

    if args.sliding_window:
      test_X, test_y = sliding_window(test_X, test_y, args.seqlen, args.add_time)

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
  parser.add_argument("--cvfolds", type=int, default=5)
  parser.add_argument("--add_time", type=bool, default=False)
  parser.add_argument("--model", choices=['lstm', 'bilstm','FF'], default='bilstm')
  parser.add_argument("--downsample_file",type=str,default=None)
  parser.add_argument("--downsample_repeat",type=int,default=None)

  args = parser.parse_args()
  assert args.normalize == 'none', "Normalization not supported"

  X, y = load_data(args.features, args.locations)
  print np.shape(X)


  if args.downsample_file is not None and args.downsample_repeat is not None:
     idx_list = np.loadtxt("data/Downsample_idx/"+args.downsample_file,dtype=int)
     indexes= idx_list[args.downsample_repeat,:]
     print args.downsample_file, np.shape(idx_list), "\n using indexes (shape,values):",np.shape(indexes),":", indexes
     X=X[:,indexes]
  else:
     assert False, "You need to specify downsample file containing IDX to use"



  if args.model == 'lstm':
    model = RatLSTM(**vars(args))
  elif args.model == 'bilstm':
    model = RatBiLSTM(**vars(args))
  elif args.model == 'FF':
    model = RatFF(**vars(args))
  else:
    assert False, "Unknown model %s" % args.model

  input_size = X.shape[1]
  output_size = y.shape[1]
  if args.add_time: #in this case we have "seqlen" (usually 100) more inputs
	input_size += args.seqlen
  model.init(input_size, output_size)


  preds, targets = cvpredict(model, X, y, args)
  print "preds shape:", preds.shape, "targets shape:", targets.shape
  np.savez_compressed(args.preds_path, preds=preds, targets=targets)
  print "mse = %g, mean dist = %g, median dist = %g" % (mse(preds, targets), mean_distance(preds, targets), median_distance(preds, targets))
