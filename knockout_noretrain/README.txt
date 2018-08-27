In this folder you find everything necessary for the results of knockout analysis from the article
"Efficient neural decoding of self-location with a deep recurrent network"

"data" folder contains the original complete input data, from where we will knock each neuron out one by one
"models" folder contains model that were trained on complete data and that will be asked to make predictions using knocked-out data

"R2192_KO_{N}" folders contain logfiles (.txt) summarizing the prediction accuracy with N-th neuron knocked out. 
There are 5 log files in each folder, because knockout analysis used 5 different runs of 10-fold CV. 
Results reported in the article are based on the averages over these 5 runs.
