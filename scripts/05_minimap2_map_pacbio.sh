#!/usr/bin/env bash
#SBATCH --job-name=minimap2_hifi
#SBATCH --partition fast
#SBATCH --mem 40G
#SBATCH --cpus-per-task 8
#SBATCH -o %x-%j.out
#SBATCH -e %x-%j.err

# 05 - Map PacBio HiFi (CCS) reads to the full HiFiasm assembly
# Tool:   Minimap2 2.24 + samtools
# Adapted from a minimap2 sbatch script written for another project (ONT array job).
# NOTE:   Resources (memory, CPUs, partition) are placeholders; adjust to your cluster.
# Input:  adapter-clean HiFi reads (step 01) + primary contig assembly (HiFiasm, FASTA)
# Output: minimap2_css_sorted.bam (+ .bai), used for Anvi'o profiling in step 06

set -euo pipefail

module load minimap2
module load samtools

REF=01_dpulchra_CCS.asm.bp.p_ctg.fasta
READS=reads/dpulchra_CCS.cutadapt.fastq.gz
OUT=minimap2_css_sorted.bam
THREADS=${SLURM_CPUS_PER_TASK:-8}

minimap2 -ax map-hifi -t "$THREADS" "$REF" "$READS" \
    | samtools sort -@ "$THREADS" -o "$OUT" -

samtools index "$OUT"
