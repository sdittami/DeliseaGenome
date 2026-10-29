#!/usr/bin/env bash
#SBATCH --job-name=braker3
#SBATCH --cpus-per-task 8
#SBATCH --time 24:00:00
#SBATCH --mem 64G
#SBATCH -o %x-%j.out
#SBATCH -e %x-%j.err


GENOME=../../finalresults/assemblies/02_repeatmasker/02_dpulchra_CCS.asm.bp.p_ctg.bin52.fa.masked
PROT=../prothint/Eukaryota.fa
TOPHAT_DIR=../RNAseqMapping/tophat2
BAM=${TOPHAT_DIR}/accepted_hits_sorted.bam
AUGUSTUS_CONFIG=$PWD/augustus_config/config
THREADS=${SLURM_CPUS_PER_TASK:-8}

# --- Preparation -------------------------------------------------------------

# OrthoDB v11 Eukaryota protein set (BRAKER's partitioned OrthoDB; check the URL
# against the current BRAKER documentation)
if [ ! -s "$PROT" ]; then
    mkdir -p "$(dirname "$PROT")"
    wget -O "${PROT}.gz" https://bioinf.uni-greifswald.de/bioinf/partitioned_odb11/Eukaryota.fa.gz
    gunzip "${PROT}.gz"
fi

# Coordinate-sort the TopHat2 alignments
if [ ! -s "$BAM" ]; then
    samtools sort -@ "$THREADS" -o "$BAM" "${TOPHAT_DIR}/accepted_hits.bam"
    samtools index "$BAM"
fi

# Writable copy of the AUGUSTUS config (BRAKER writes the trained species here)
if [ ! -d "$AUGUSTUS_CONFIG" ]; then
    mkdir -p "$(dirname "$AUGUSTUS_CONFIG")"
    cp -r /usr/share/augustus/config "$AUGUSTUS_CONFIG"
fi

# --- BRAKER3 -------------------------------------------------------------------

braker.pl \
    --threads="$THREADS" \
    --gff3 \
    --genome="$GENOME" \
    --prot_seq="$PROT" \
    --bam="$BAM" \
    --AUGUSTUS_CONFIG_PATH="$AUGUSTUS_CONFIG"
