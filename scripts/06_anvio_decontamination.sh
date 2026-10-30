##ANVIO 8 Contigs db
anvi-gen-contigs-database -f 01_dpulchra_CCS.asm.bp.p_ctg.fasta -o contigs.db -n "Delisea_pulchra"
anvi-run-hmms --num-threads 12 -c contigs.db
anvi-setup-ncbi-cogs  --cog-data-dir ./COGs/
anvi-setup-ncbi-cogs  --reset --cog-data-dir ./COGs/
anvi-run-ncbi-cogs --num-threads 12 --cog-data-dir COGs/ -c contigs.db 

##KAIJU
anvi-get-sequences-for-gene-calls -c contigs.db -o gene_calls.fa
wget https://kaiju-idx.s3.eu-central-1.amazonaws.com/2023/kaiju_db_nr_euk_2023-05-10.tgz
srun tar xzf kaiju_db_nr_euk_2023-05-10.tgz
rm kaiju_db_nr_euk_2023-05-10.tgz
module load kaiju

srun --cpus-per-task 20 --mem=300G kaiju -z 20 -v -t kaiju/nodes.dmp -f kaiju/kaiju_db_nr_euk.fmi -i gene_calls.fa -o kaiju/gene_calls_nr.out2
kaiju-addTaxonNames -t kaiju/nodes.dmp -n kaiju//names.dmp -i kaiju/gene_calls_nr.out2 -o kaiju/gene_calls_nr.names2 -r superkingdom,phylum,order,class,family,genus,species
anvi-import-taxonomy-for-genes -i kaiju/gene_calls_nr.names2 -c kaiju/contigs.db -p kaiju
anvi-import-taxonomy-for-genes -i kaiju/gene_calls_nr.names2 -c contigs.db -p kaiju --just-do-it

## profiles 
srun --mem=20G anvi-profile -i minimap2_css_sorted.bam -c contigs.db --output-dir profile_pacbio --sample-name PacBio
srun --mem=20G anvi-profile -i MiSeq2_sorted.bam -c contigs.db --output-dir profile_miseq --sample-name Miseq 
srun --mem=20G anvi-merge profile_miseq/PROFILE.db profile_pacbio/PROFILE.db -o profile_merged -c contigs.db 

## Taxonomy (anvio)
anvi-run-scg-taxonomy --scgs-taxonomy-data-dir scgs-data -c contigs.db

## ANVI-INTERACTIVE
hostname -I
anvi-interactive -p profile_merged/PROFILE.db -c contigs.db
