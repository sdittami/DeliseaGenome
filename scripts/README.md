# *Delisea pulchra* genome: analysis scripts

Scripts used to decontaminate, annotate and prepare for submission the *Delisea pulchra* genome assembly (PacBio HiFi/CCS + Illumina MiSeq, plus published RNA-seq).

> These scripts are a record of the commands run on a SLURM cluster (`srun`, `module load`). Paths are specific to the original environment and need to be adapted.

## Repository layout

```
scripts/
├── 01_cutadapt_trim_hifi.sh
├── 02_hifiasm_assembly.sh
├── 03_novoplasty_organelles.sh
├── 04_bowtie2_map_miseq.sh
├── 05_minimap2_map_pacbio.sh
├── 06_anvio_decontamination.sh
├── 07_tophat2_map_rnaseq.sh
├── 08_repeatmodeler_repeatmasker.sh
├── 09_braker3_gene_prediction.sh
├── ena_submission/
│   ├── 1_remove_duplicate_features.py
│   ├── 2_clean_embl_qualifiers.py
│   └── 3_deduplicate_embl_features.py
└── utils/
    └── gc_content.sh
```



## Scripts

### 01 — `01_cutadapt_trim_hifi.sh`
Removes residual SMRTbell adapters from the PacBio HiFi (CCS) reads with Cutadapt 2.8. *Template script: check adapter sequences and parameters against the original run.*

### 02 — `02_hifiasm_assembly.sh`
De novo assembly of the cleaned HiFi reads with HiFiasm 0.15.1 (default parameters, 16 threads), followed by GFA → FASTA conversion of the primary contigs (`01_dpulchra_CCS.asm.bp.p_ctg.fasta`).

### 03 — `03_novoplasty_organelles.sh`
Assembles the **mitochondrial and plastid genomes** with NOVOPlasty 4.3.4 from the MiSeq reads, using two config files (one per organelle). The seed/reference sequences are the *Chondrus crispus* plastid (HF562234.1) and mitochondrion (NC_001677.2).

### 04 — `04_bowtie2_map_miseq.sh`
Maps the MiSeq paired-end reads to the full assembly with Bowtie2 (`--local`), then converts, sorts and indexes the result with samtools. Output: `MiSeq_sorted.bam`, used for coverage profiling in step 06.

### 05 — `05_minimap2_map_pacbio.sh`
Maps the HiFi reads to the full assembly with Minimap2 (`-ax map-hifi`) and sorts/indexes the result with samtools. Output: `minimap2_css_sorted.bam`, used for coverage profiling in step 06.

### 06 — `06_anvio_decontamination.sh`
Removal of non-target (contaminant) contigs with Anvi'o 8:
1. Build the contigs database and annotate it with HMMs and NCBI COGs.
2. Predict taxonomy of gene calls with Kaiju (nr_euk database, 2023-05-10) and import it into Anvi'o.
3. Profile the MiSeq and PacBio CCS mappings and merge the profiles.
4. Run Anvi'o single-copy-gene taxonomy and cluster contigs with CONCOCT.
5. Launch `anvi-interactive` for manual binning. The bin with substantial MiSeq and PacBio coverage (bin 52) is the *D. pulchra* genome.

### 07 — `07_tophat2_map_rnaseq.sh`
Builds a Bowtie2 index of the clean genome and maps the paired-end RNA-seq libraries (24 libraries: Control, AD1, AD10 at 24 h and 48 h, 4 replicates each; deduplicated reads from Hudson et al. 2022) with TopHat 2.1.1. The resulting alignments are used as evidence for gene prediction and to check which contigs are supported by transcripts.

### 08 — `08_repeatmodeler_repeatmasker.sh`
Builds a repeat library from the clean genome with RepeatModeler 2.0.3 (713 families found) and soft-masks the genome with RepeatMasker 4.1.2 before gene prediction.

### 09 — `09_braker3_gene_prediction.sh`
Structural gene annotation with BRAKER3 (braker.pl 3.0.5, ETP mode) using the soft-masked genome, the sorted TopHat2 alignments and the OrthoDB v11 Eukaryota protein set. Also prepares the inputs (protein download, BAM sorting, AUGUSTUS config copy). The `braker.pl` call is taken from the BRAKER log.

### `ena_submission/`
Post-processing of the EMBL flat file generated for submission to ENA, to fix validation errors. Run in this order:

| Script | Purpose |
|---|---|
| `1_remove_duplicate_features.py` | Drops features with identical type and location (first pass) |
| `2_clean_embl_qualifiers.py` | Removes `codon_start`/`transl_table` from non-CDS features and keeps only one `locus_tag` per feature; logs removals |
| `3_deduplicate_embl_features.py` | Merges features sharing type and location, combining their qualifiers (notes are concatenated); logs merges |

### `utils/gc_content.sh`
Reports GC content (integer %) per sequence of a single-line-per-sequence FASTA file. Usage: `bash gc_content.sh genome.fasta`.


## Software versions

Cutadapt 2.8 · HiFiasm 0.15.1 · NOVOPlasty 4.3.4 · Anvi'o 8 · Bowtie2 2.5.1 · Minimap2 2.24 · Kaiju 1.9.2 · TopHat 2.1.1 · RepeatModeler 2.0.3 · RepeatMasker 4.1.2 · BRAKER3 (braker.pl 3.0.5) · BUSCO 5.5.0 · GAG 2.0.1 · OrthoFinder 2.5.2

## Citation

Dittami, S. M., Hudson, J., Brillet-Guéguen, L., Ficko-Blean, E., Tanguy, G., Rousvoal, S., Legeay, E., Markov, G. V., Delage, L., Godfroy, O., Corre, E., Collén, J., Leblanc, C., & Egan, S. (2026). The genome of the Delisea pulchra: a resource for the study of chemical host-microbe interactions in red algae [Preprint]. bioRxiv. https://doi.org/10.64898/2026.03.31.715562
