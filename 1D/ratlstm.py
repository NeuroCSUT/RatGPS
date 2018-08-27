import argparse
import numpy as np
from keras.models import Model
from keras.losses import mean_squared_error
from keras.layers import Input, Dense, Activation, Dropout
from keras.layers import SimpleRNN, LSTM, GRU
from keras.callbacks import ModelCheckpoint, EarlyStopping, LearningRateScheduler, Callback
import keras.backend as K
from ratdata import *

def mse(y, t, axis=-1):
    return (np.square(y - t).mean(axis=axis).mean())

def mean_distance(y, t, axis=-1):
    return np.mean(np.sqrt(np.sum((y - t)**2, axis=axis)))

def median_distance(y, t, axis=-1):
    return np.median(np.sqrt(np.sum((y - t)**2, axis=axis)))

def make_batches(size, batch_size):
    nb_batch = int(np.ceil(size / float(batch_size)))
    return [(i * batch_size, min(size, (i + 1) * batch_size)) for i in range(0, nb_batch)]

class RatLSTM:
  def __init__(self, **kwargs):
    self.__dict__.update(kwargs)

  def init(self, nb_inputs, nb_outputs, gradients=False):
    print "Creating model..."

    if self.rnn == 'simple':
      RNN = SimpleRNN
    elif self.rnn == 'gru':
      RNN = GRU
    elif self.rnn == 'lstm':
      RNN = LSTM
    else:
      assert False, "Invalid RNN"    

    h = x = Input(shape=(self.seqlen, nb_inputs))
    for i in xrange(self.layers):
      return_sequences = False
      if i == 0: #for first layer need to specify input size
        if self.layers>1: L1_return_sequences = True
        layer = RNN(self.hidden_nodes, input_shape = (self.seqlen, nb_inputs), return_sequences=L1_return_sequences)
      else:
        layer = RNN(self.hidden_nodes, return_sequences=return_sequences)
      
      h = layer(h)
      if self.dropout > 0:
        h = Dropout(self.dropout)(h)
    
    y = Dense(nb_outputs)(h)

    self.model = Model(x, y)
    self.model.summary()
    self.model.compile(loss=mean_squared_error, optimizer=self.optimizer)

    if gradients:
        print "Preparing gradient function..."
        y_true = K.placeholder(shape=K.int_shape(y))
        loss_tensor = mean_squared_error(y_true, y)
        loss_tensor = K.mean(loss_tensor)
        grads_tensor = K.gradients(loss_tensor, [x])
        self.grads_function = K.function([x, y_true, K.learning_phase()], grads_tensor)
        # self.grads_function(X_test, y_test, 0)

  def fit(self, train_X, train_y, valid_X, valid_y, save_path):
    callbacks = [ModelCheckpoint(filepath=save_path, verbose=1, save_best_only=self.save_best_model_only)]
    if self.patience:
      callbacks.append(EarlyStopping(patience=self.patience, verbose=1))
    if self.lr_epochs:
      def lr_scheduler(epoch):
        lr = self.lr * self.lr_factor**int(epoch / self.lr_epochs)
        print "Epoch %d: learning rate %g" % (epoch + 1, lr)
        return lr
      callbacks.append(LearningRateScheduler(lr_scheduler))

    self.model.fit(train_X, train_y, batch_size=self.batch_size, epochs=self.epochs, validation_data=(valid_X, valid_y), 
        shuffle=self.train_shuffle, verbose=self.verbose, callbacks=callbacks)

  def eval(self, X, y, load_path):
    self.model.load_weights(load_path)
    pred_y = self.model.predict(X, batch_size=self.batch_size)

    err = mse(pred_y, y)
    dist = mean_distance(pred_y, y)

    return (err, dist)

  def predict(self, X, load_path):
    self.model.load_weights(load_path)

    pred_y = self.model.predict(X, batch_size=self.batch_size)
    print 'pred_y:', pred_y.shape
    return pred_y

  def gradients(self, X, y, load_path):
    print load_path
    self.model.load_weights(load_path)

    grads = np.empty_like(X)
    for start, end in make_batches(X.shape[0], self.batch_size):
        grads[start:end] = self.grads_function([X[start:end],y[start:end],0])[0]
    return grads

  def last_layer_activation(self, X, load_path):
    print load_path
    self.model.load_weights(load_path)
    
    activation = np.empty([len(X),512])
    print self.model.layers
    print self.model.layers[-3],  dir(self.model.layers[-3])
    act_getter_function = K.function(self.model.inputs + [K.learning_phase()], [self.model.layers[-3].output])
    for start, end in make_batches(X.shape[0], self.batch_size):
        out = act_getter_function([X[start:end],0])[0]
        activation[start:end,:] = out
    return activation

  def get_weights(self):
    print self.model
    return self.model.get_weights()

  def set_weights(self, weights):
    return self.model.set_weights(weights)

def add_model_params(parser):
  parser.add_argument("--rnn", choices=['simple', 'lstm', 'gru'], default='lstm')
  parser.add_argument("--hidden_nodes", type=int, default=512)
  parser.add_argument("--batch_size", type=int, default=64)
  parser.add_argument("--epochs", type=int, default=50)
  parser.add_argument("--patience", type=int, default= 0) # used for early stopping, if 0, no early stop
  parser.add_argument("--verbose", type=int, choices=[0, 1, 2], default=1)
  parser.add_argument("--train_shuffle", choices=['true', 'false'], default='true')
  parser.add_argument("--dropout", type=float, default=0.5)
  parser.add_argument("--layers", type=int, choices=[1, 2, 3], default=2)
  parser.add_argument("--optimizer", choices=['adam', 'rmsprop'], default='rmsprop')
  parser.add_argument("--save_best_model_only", type=str2bool, default=False)
  parser.add_argument("--lr", type=float, default=0.001)
  parser.add_argument("--lr_epochs", type=int)
  parser.add_argument("--lr_factor", type=float, default=0.1)

if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  add_data_params(parser)
  add_model_params(parser)
  parser.add_argument("save_path")
  args = parser.parse_args()


  X, y = load_data(args.features, args.locations)
  train_X, train_y, valid_X, valid_y = split_transform(X, y, args)

  model = RatLSTM(**vars(args))
  model.init(X.shape[1], y.shape[1])
  model.fit(train_X, train_y, valid_X, valid_y, args.save_path + '.hdf5')
  terr, tdist = model.eval(train_X, train_y, args.save_path + '.hdf5')
  verr, vdist = model.eval(valid_X, valid_y, args.save_path + '.hdf5')
  print 'train mse = %g, validation mse = %g' % (terr, verr)
  print 'train dist = %g, validation dist = %g' % (tdist, vdist)
