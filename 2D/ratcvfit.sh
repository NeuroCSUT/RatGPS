#!/usr/bin/env bash
label=$1
shift
#nohup srun --partition=gpu --gres=gpu:1 --constraint=K20 python ratcvfit.py $label --verbose 2 $* >$label.log &
nohup python ratcvfit.py $label --verbose 2 $* >$label.log
