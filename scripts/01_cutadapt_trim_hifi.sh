#!/usr/bin/env bash
#SBATCH --job-name=cutadapt_hifi
#SBATCH --cpus-per-task 8
#SBATCH --mem 16G
#SBATCH -o %x-%j.out
#SBATCH -e %x-%j.err


module load cutadapt  

IN=${1:-reads/dpulchra_CCS.fastq.gz}
OUT=${2:-reads/dpulchra_CCS.cutadapt.fastq.gz}

# PacBio blunt SMRTbell adapter and its reverse complement
ADAPTER_FWD=ATCTCTCTCAACAACAACAACGGAGGAGGAGGAAAAGAGAGAGAT
ADAPTER_REV=ATCTCTCTCTTTTCCTCCTCCTCCGTTGTTGTTGTTGAGAGAGAT

cutadapt -j "${SLURM_CPUS_PER_TASK:-8}" \
    -b "$ADAPTER_FWD" -b "$ADAPTER_REV" \
    -O 35 -e 0.1 \
    -o "$OUT" "$IN" \
    > "${OUT%.fastq.gz}.cutadapt_report.txt"

