#!/usr/bin/env bash
#SBATCH --job-name=repeats
#SBATCH --cpus-per-task 8
#SBATCH --mem 32G
#SBATCH -o %x-%j.out
#SBATCH -e %x-%j.err

module load repeatmodeler repeatmasker  

GENOME=../../finalresults/assemblies/02_dpulchra_CCS.asm.bp.p_ctg.bin52.fa
DB=DpulchraBin52
THREADS=${SLURM_CPUS_PER_TASK:-8}
OUTDIR=02_repeatmasker

# 1. Build the RepeatModeler database
BuildDatabase -name "$DB" "$GENOME"

# 2. De novo repeat discovery (rmblast engine; LTRStruct not enabled, as in the log)
RepeatModeler -database "$DB" -engine ncbi -threads "$THREADS"
# -> 713 repeat families found; output in DpulchraBin52-families.fa

# 3. Soft-mask the genome with the species-specific library (-xsmall = lowercase)
mkdir -p "$OUTDIR"
RepeatMasker -lib "${DB}-families.fa" -xsmall -gff \
    -pa $(( THREADS > 4 ? THREADS / 4 : 1 )) \
    -dir "$OUTDIR" "$GENOME"
