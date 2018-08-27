#!/usr/bin/env bash
                                                                                                                                                            
label=R2192
seq_len=100


for i in 1400;
do
at=$(($i/40))
for repeat in 9;
do
  python ratcvpred_downsample.py "$label"_models/downsample/downsample15_"$label"_1x"$i"_seq"$seq_len"_ep50_b64_sample"$repeat" --features data/"$label"_1x"$i"_at"$at"_step200_bin100-RAW_feat.dat --locations data/"$label"_1x"$i"_at"$at"_step200_bin100-RAW_pos.dat --batch_size 64 --epochs 50 --patience 0 --layers 2 --hidden_nodes 512 --cvfolds 10 --train_set 1 --save_best_model_only false --seqlen 100 --verbose 2 --downsample_file random_IDs_15.txt --downsample_repeat "$repeat" R2192_models/downsample/predictions15_"$repeat" >"$label"_models/downsample/downsample15pred_"$label"_1x"$i"_ep50_b64_sample"$repeat".txt 
  sleep 3
done
done

