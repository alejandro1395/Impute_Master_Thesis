#!/bin/bash

module load gcc/4.9.3
module load PYTHON/3.6.3

#REFERENCE
REF="/home/devel/marcmont/scratch/snpCalling_hg19/chimp/assembly/BWA/hg19.fa"
BIN="/scratch/devel/avalenzu/Impute_Master_Project/bin/IMPUTE/impute_v2.3.2_x86_64_static/"

#NEEDED FILES AND OUTPUT

STUDY_GENS="/scratch/devel/avalenzu/Impute_Master_Project/data/STUDY_GENS/GEN_FILES/"

MAP_FILES="/scratch/devel/avalenzu/Impute_Master_Project/data/MAP_RECOMB/BIG_MAP_HG18/final_maps_with_cM/"

REF_PANELS="/scratch/devel/avalenzu/Impute_Master_Project/data/PANEL_REF/"

OUTDIR="/scratch/devel/avalenzu/Impute_Master_Project/results/Impute_out/"

mkdir -p ${OUTDIR}

#CHIMPS AND CHROMOSOMES

chimp_names="verus-McVean"
chromosomes="22"

#Iterates for chr and chimps
echo $chimp_names | tr " " "\n" | while read chimp_name;
do mkdir -p ${OUTDIR}Pan_troglodytes_${chimp_name}
ls ${STUDY_GENS}Pan_troglodytes_${chimp_name}/chr${chromosomes}/*.gen.gz | while read filepath; 
do in_file=$(ls $filepath | tr " " "\n" | rev | cut -d/ -f1 | rev | tr "\n" " ")
input=$(echo $in_file)
mkdir -p ${OUTDIR}Pan_troglodytes_${chimp_name}/chr${chromosomes} 
mkdir -p ${OUTDIR}Pan_troglodytes_${chimp_name}/chr${chromosomes}/out
mkdir -p ${OUTDIR}Pan_troglodytes_${chimp_name}/chr${chromosomes}/qu

#LOOP CHUNKS IN FIRST CHROMOSOME

num_lines=$(zcat $filepath | wc -l)
last_pos=$(zcat $filepath | sed -n -e ${num_lines},${num_lines}p | cut -d " " -f 3)
num_chunks=$(echo $last_pos/1000000 | bc )
echo $num_chunks
num_chunks2=$(echo $num_chunks+1 | bc)
start=0

for chunk in $(seq 1 $num_chunks2)
do endchr=$(echo $start+1000000 | bc)
startchr=$(echo $start+1 | bc) 
echo "#!/bin/bash
module purge
module load gcc/4.9.3-gold
module load GATK/4.0.8.1
module load TABIX/0.2.6
module load VCFTOOLS/0.1.7
module load zlib/1.2.8
module load intel/16.3.067
module load lapack/3.2.1
module load PLINK/1.90b
#MAIN SCRIPT

${BIN}impute2 \
-m ${MAP_FILES}final_chr${chromosomes}.map \
-g ${STUDY_GENS}Pan_troglodytes_${chimp_name}/chr${chromosomes}/$input \
-g_ref ${REF_PANELS}/chr${chromosomes}/ref_panel_chr${chromosomes}.gen.gz \
-int $startchr $endchr \
-Ne 20000 \
-o ${OUTDIR}Pan_troglodytes_${chimp_name}/chr${chromosomes}/chr${chromosomes}.chunk${chunk}.unphased.impute2 \
-o_gz" > ${OUTDIR}Pan_troglodytes_${chimp_name}/chr${chromosomes}/qu/impute_chr${chromosomes}_chunk${chunk}.sh
jobname=$(echo ${OUTDIR}Pan_troglodytes_${chimp_name}/chr${chromosomes}/qu/impute_chr${chromosomes}_chunk${chunk}.sh)
chmod 755 $jobname
start=$endchr

/scratch/devel/avalenzu/CNAG_interface/submit.py -c ${jobname} \
-o ${OUTDIR}Pan_troglodytes_${chimp_name}/chr${chromosomes}/out/impute_chr${chromosomes}.out \
-e ${OUTDIR}Pan_troglodytes_${chimp_name}/chr${chromosomes}/out/impute_chr${chromosomes}.err \
-n ${chromosomes}_chunk${chunk} -u 8 -t 1 -w 23:50:00
done; done; done;
