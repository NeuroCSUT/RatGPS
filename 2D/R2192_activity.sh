#!/usr/bin/env bash
                                                                                                                                                            
for v in 1;
do
  python2 cv_activity.py R2192_models/simple_window_scan_R2192_1x1400_seq100_ep50_b64_"$v" R2192_models/simple_activity_R2192_1x1400_v"$v" --features data/R2192_1x1400_at35_step200_bin100-RAW_feat.dat --locations data/R2192_1x1400_at35_step200_bin100-RAW_pos.dat --batch_size 64 --epochs 50 --patience 0 --layers 2 --hidden_nodes 512 --cvfolds 10 --train_set 1 --save_best_model_only false --seqlen 100 --verbose 2 >R2192_models/simple_activity_R2192_1x1400_v"$v".txt 
  sleep 3
done

