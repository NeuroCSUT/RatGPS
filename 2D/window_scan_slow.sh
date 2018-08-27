#!/usr/bin/env bash
                                                                                                                                                            
label=$1
seq_len=100


for i in 800 600 400 200;
do
at=$(($i/40))
for v in 1;
do
  THEANO_FLAGS="device=gpu1" python ratcvfit.py "$label"_models/window_scan_"$label"_1x"$i"_seq"$seq_len"_ep50_b64_"$v" --features data/"$label"_1x"$i"_at"$at"_step200_bin100-RAW_feat.dat --locations data/"$label"_1x"$i"_at"$at"_step200_bin100-RAW_pos.dat --batch_size 64 --epochs 50 --patience 0 --model lstm --layers 2 --hidden_nodes 512 --cvfolds 10 --train_set 1 --save_best_model_only false --seqlen 100 --sliding_window 1 --split_shuffle False --verbose 2 >"$label"_models/window_scan_"$label"_1x"$i"_ep50_b64_"$v".txt 
  sleep 3
done
done

