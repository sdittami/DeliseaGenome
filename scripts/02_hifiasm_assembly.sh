#!/usr/bin/env bash

module load hifiasm   # adjust to your cluster

READS=reads/dpulchra_CCS.cutadapt.fasta
OUTDIR=01_hifiasm
PREFIX=01_dpulchra_CCS.asm

mkdir -p "$OUTDIR"
hifiasm -o "$OUTDIR/$PREFIX" -t 16 "$READS"
