#!/usr/bin/env bash
label=R2192
shift

for n in `seq 0 62`;
do
mkdir "$label"_KO_"$n"
for i in 6 7 8 9 10;
do
  python ratcvpred.py models/window_scan_"$label"_1x1400_seq100_ep50_b64_"$i" --features data/"$label"_1x1400_at35_step200_bin100-RAW_feat.dat --locations data/"$label"_1x1400_at35_step200_bin100-RAW_pos.dat --batch_size 64 --epochs 50 --patience 0 --layers 2 --hidden_nodes 512 --cvfolds 10 --train_set 1 --seqlen 100 --verbose 2 --KO $n "$label"_KO_"$n"/"$label"_KO_"$n"_1x1400_v"$i" >"$label"_KO_"$n"/KO_"$n"_predictions_"$i".txt
  sleep 5
done
done
