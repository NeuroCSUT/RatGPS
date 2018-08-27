#!/usr/bin/env bash
                                                                                                                                                            
label=$1
seq_len=100


for i in 1400;
do
at=$(($i/40))
for v in 1 2 3 4 5;
do
  python2 ratcvpred.py "$label"_models/simple_window_scan_"$label"_1x"$i"_seq"$seq_len"_ep50_b64_"$v" --features data/"$label"_1x"$i"_at"$at"_step200_bin100-RAW_feat.dat --locations data/"$label"_1x"$i"_at"$at"_step200_bin100-RAW_pos.dat --batch_size 64 --epochs 50 --patience 0 --layers 2 --hidden_nodes 512 --cvfolds 10 --train_set 1 --save_best_model_only false --seqlen 100 --verbose 2 "$label"_models/simple_windowscan_"$label"_1x"$i"_predictions_"$v" >"$label"_models/simple_pred_window_scan_"$label"_1x"$i"_ep50_b64_"$v".txt 
  sleep 3
done
done

