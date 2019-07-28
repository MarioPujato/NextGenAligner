================================================================================
NextGenAligner
Next-Generation sequencing alignment pipeline

Version:    1.4.4
Created:    011017
Modified:   062619
Written by: Mario Pujato
================================================================================


================================================================================
EXTERNAL DEPENDENCIES

  vdb-validate # Compares checksums for downloaded SRA files
  fastq-dump   # Extract FASTQ files from SRA files
  fastqc       # General quality control on raw reads

  trim_galore  # Trims bad quality reads
  cutadapt     # Needed by trim_galore

  STAR         # Aligner
  hisat2       # Aligner
  bowtie2      # Aligner

  samtools     # Manipulates SAM files (version 1.3 or higher)
  bedtools     # Manipulates BED files
  picard-tools # Removes duplicate reads
  macs2        # Calls peaks from BAM files


================================================================================
USAGE: NextGenAligner [options] <arguments>

  [options]

    ARGUMENTS
      -O  Name of output folder
      -C  Configuration file (a sample file can be generated using option -y)
      -I  SRA IDs. Comma-separated list
            Based on these IDs, SRA files will be downloaded from NCBI
      -F  FASTQ files (paired-end reads experiments). Comma-separated list
            Paired-end reads experiments should be given in pairs, separated by ":"
            (example: EXP1_FQ1:EXP1_FQ2,EXP2_FQ1:EXP2_FQ2,EXP3_FQ,EXP4_FQ...)
      -B  BAM files. Comma-separated list
            The file must be sorted by position
            Duplicate reads will be removed unless the -r option is set
      -X  Path to index files (STAR, HISAT2 and BOWTIE2 are supported)
            For BOWTIE2, add to the end of the index path the base name common
             to all the .bt2 files, like /path_to_index_files/hg19
            For HISAT2, add to the end of the index path the base name common
             to all the .ht2 files, like /path_to_index_files/hg19
            For STAR, nothing need to be added to the index path
      -p  (optional) Number of threads to use in parallelized routines
            (it defaults to use all available threads)

    SEQUENCE ALIGNER
      -s  Process RNA-seq experiment using the STAR aligner (34Gb o memory required!)
      -t  Process RNA-seq experiment using the HISAT2 aligner (low memory usage)
      -u  Process experiment using the BOWTIE2 aligner (low memory usage)
          BOWTIE2 is NOT suited for processing of RNA-seq experiments

    SWITCHES
      -h  This help message
      -i  Integrate/Concatenate multiple FASTQ files into one before alignment
            NOTE: It only works if either a list of SRA or FASTQ files is given
            This might be useful when a single GSM id points to multiple SRR ids,
            which are a single FASTQ file split into multiple SRA files
      -a  Align FASTQ files to genome
      -c  Call peaks from BAM file
      -q  Perform quality control of raw-reads (for each FASTQ file)
      -r  Retain duplicate reads in BAM output
            (the default behavior is to remove duplicate reads)
      -x  Print pipeline scheme to the screen
      -y  Generate a default configuration file
================================================================================


================================================================================
EXAMPLES:

  Download and generate FASTQ files from SRA ID
    > NextGenAligner -I SRR1608989 -C CONFIG.txt

  ChIP-seq experiments or similar:
  Align FASTQ reads to hg19 genome (starting from SRA ID)
    > NextGenAligner -I SRR1608989 -C CONFIG.txt -uX path_to_BOWTIE2_aligner_index_files/hg19

  RNA-seq experiments:
  Align FASTQ reads to hg19 genome (starting from SRA ID)
    > NextGenAligner -I SRR1608989 -C CONFIG.txt -sX path_to_STAR_aligner_index_files
    > NextGenAligner -I SRR1608989 -C CONFIG.txt -tX path_to_HISAT2_aligner_index_files/hg19

  Align to genome using paired-end reads
    > NextGenAligner -F SRR1_1.fq.gz:SRR1_2.fq.gz -C CONFIG.txt -sX path_to_STAR_aligner_index_files

  Align to genome using single and paired-end reads from different experiments
    > NextGenAligner -F SRR1_1.fq.gz:SRR1_2.fq.gz,SRR2.fq.gz -C CONFIG.txt -sX path_to_STAR_aligner_index_files

  Call peaks on BAM files
    > NextGenAligner -cB SRR1.bam,SRR2.bam -C CONFIG.txt
================================================================================


================================================================================
PIPELINE SCHEME

The pipeline can be used to start and/or generate any intermediate file in the scheme.


 +-------[I]                                     
 |         |                                     
 |  SRAID  |                                     
 |         |                                     
 +---------+                                     
      |                                          
      |                                          
      v                                          
 +-------[F]       +-------[B]       +---------+ 
 |         |       |         |       |         | 
 |  FASTQ  | ----> |   BAM   | ----> |   BED   | 
 |         |  (a)  |         |  (c)  |         | 
 +---------+       +---------+       +---------+ 
    (q)                 ^                        
                        |                        
                        |                        
                   +-------[X]                   
                   |         |                   
                   |  INDEX  |                   
                   |         |                   
                   +---------+                   

Input files:

-I  SRA ID (i.e. SRR1608989 )
-F  Fastq file (paired-end reads should be given separated with ":", like: FQ1:FQ2)
-B  Alignment file (BAM format)
-C  Configuration file (can be generated with the -y option)
-O  Name of output folder (all files are saved here)

Priority of input files:

  If multiple input files are privided (e.g.: SRA_ID, FASTQ and BAM files),
  the pipeline starts with the file with the highest priority.

  I<F<B (the BAM file has the highest priority)

Genomic index files for short-read aligners:

-X  Index files for corresponding aligner (STAR, HISAT2 and BOWTIE2 are supported)
      For BOWTIE2, add to the end of the index path the base name common
       to all the .bt2 files, like /path_to_index_files/hg19
      For HISAT2, add to the end of the index path the base name common
       to all the .ht2 files, like /path_to_index_files/hg19
      For STAR, nothing need to be added to the index path

Options:

-a  Align FASTQ reads to the genome (generates BAM file)
-c  Call peaks
-p  Number of threads (default: use all available threads)
-q  Perform quality control on FASTQ files
-r  Keep duplicate reads
-s  Input data is RNA-seq (STAR alignment)
-t  Input data is RNA-seq (HISAT2 alignment)
-u  Input data is NOT RNA-seq (BOWTIE2 alignment)

Output files:
(BED) If the -c option is given, MACS2 called peaks are produced as a BED file.
      The BED file has 4 additional columns over the MACS2 output:
         1.  MACS2: chromosome
         2.  MACS2: peak start position
         3.  MACS2: peak end position
         4.  MACS2: peak name
         5.  MACS2: int(-10*log10qvalue)
         6.  MACS2: .
         7.  MACS2: fold-change
         8.  MACS2: -log10pvalue
         9.  MACS2: -log10qvalue
        10.  MACS2: relative summit position to peak start
        11.  Number of reads under the peak
        12.  Peak width
        13.  RPKM, measured as the number of reads divided by the peak width,
             multiplied by 1,000,000 divided by the total number of reads under
             all peaks
================================================================================
