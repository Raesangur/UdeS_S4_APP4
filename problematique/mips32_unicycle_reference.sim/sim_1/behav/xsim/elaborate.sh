#!/bin/bash -f
# ****************************************************************************
# Vivado (TM) v2020.2 (64-bit)
#
# Filename    : elaborate.sh
# Simulator   : Xilinx Vivado Simulator
# Description : Script for elaborating the compiled design
#
# Generated by Vivado on Mon Jul 04 03:47:40 EDT 2022
# SW Build 3064766 on Wed Nov 18 09:12:47 MST 2020
#
# Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
#
# usage: elaborate.sh
#
# ****************************************************************************
set -Eeuo pipefail
# elaborate design
echo "xelab -wto 19cce0a531df40cda0f8ee2727a22117 --incr --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot mips_unicycle_tb_behav xil_defaultlib.mips_unicycle_tb -log elaborate.log"
xelab -wto 19cce0a531df40cda0f8ee2727a22117 --incr --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot mips_unicycle_tb_behav xil_defaultlib.mips_unicycle_tb -log elaborate.log

