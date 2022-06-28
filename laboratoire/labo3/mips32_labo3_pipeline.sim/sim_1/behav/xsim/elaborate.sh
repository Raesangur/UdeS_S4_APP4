#!/bin/bash -f
# ****************************************************************************
# Vivado (TM) v2020.2 (64-bit)
#
# Filename    : elaborate.sh
# Simulator   : Xilinx Vivado Simulator
# Description : Script for elaborating the compiled design
#
# Generated by Vivado on Tue Jun 28 11:56:51 EDT 2022
# SW Build 3064766 on Wed Nov 18 09:12:47 MST 2020
#
# Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
#
# usage: elaborate.sh
#
# ****************************************************************************
set -Eeuo pipefail
# elaborate design
echo "xelab -wto 6b427e5d64664d61864af687a225e5ce --incr --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot mips_pipeline_tb_behav xil_defaultlib.mips_pipeline_tb -log elaborate.log"
xelab -wto 6b427e5d64664d61864af687a225e5ce --incr --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot mips_pipeline_tb_behav xil_defaultlib.mips_pipeline_tb -log elaborate.log
