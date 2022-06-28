#!/bin/bash -f
# ****************************************************************************
# Vivado (TM) v2020.2 (64-bit)
#
# Filename    : simulate.sh
# Simulator   : Xilinx Vivado Simulator
# Description : Script for simulating the design by launching the simulator
#
# Generated by Vivado on Tue Jun 28 14:54:46 EDT 2022
# SW Build 3064766 on Wed Nov 18 09:12:47 MST 2020
#
# Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
#
# usage: simulate.sh
#
# ****************************************************************************
set -Eeuo pipefail
# simulate design
echo "xsim mips_unicycle_tb_behav -key {Behavioral:sim_1:Functional:mips_unicycle_tb} -tclbatch mips_unicycle_tb.tcl -view /home/raesangur/github/UdeS_S4_APP4/problematique/mips_unicycle_tb_behav.wcfg -log simulate.log"
xsim mips_unicycle_tb_behav -key {Behavioral:sim_1:Functional:mips_unicycle_tb} -tclbatch mips_unicycle_tb.tcl -view /home/raesangur/github/UdeS_S4_APP4/problematique/mips_unicycle_tb_behav.wcfg -log simulate.log

