srun --cpus-per-task 2 bowtie2 -q --local -x 01_dpulchra_CCS.asm.bp.p_ctg -1 ../../archive/MiSeq/Delisea-pulchra_S1_L001_R1_001.fastq.gz -2 ../../archive/MiSeq/Delisea-pulchra_S1_L001_R2_001.fastq.gz -S MiSeq.sam
samtools sort MiSeq.sam -o MiSeq_sorted.bam
rm MiSeq.sam
samtools index MiSeq_sorted.bam
