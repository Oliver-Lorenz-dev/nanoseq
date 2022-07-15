#!/bin/bash

usage() {
  cat <<EOT
Usage: ./$(basename $0) <OPTION>...
       Generates samplesheet.csv file for nf-core/nanoseq pipeline in demultiplexing and variant calling mode

       -b,
       Sequencing barcode kit used (mandatory)
       -r,
       Directory containing all references needed for the samplesheet (mandatory)
       -f,
       Directory containing the fastq to be analysed (mandatory)

EOT
}

if [[ "$#" == "0" ]]; then
    usage
    exit 0
fi

while getopts "b:f:r:" arg;
do
    case $arg in
      b) barcode="${OPTARG}";;
      f) fastq_dir="${OPTARG}";;
      r) reference_dir="${OPTARG}";;
    esac
done

if  [ ! ${barcode} ] || [ ! ${fastq_dir} ] || [ ! ${reference_dir} ]; then
    echo "Please ensure all necessary arguments have been entered."
    echo
    usage
    exit 0
fi

echo "group,replicate,barcode,input_file,fasta,gtf" > samplesheet.csv

fastq_sample_name=$(ls -l $fastq_dir | tail -1 | awk '{ print $NF }' | sed 's|.fastq.gz||g')
references=$(ls -l $reference_dir | tail -n +2 | awk '{ print $NF }' | sed "s|^|./${reference_dir}/|g")

for ref in $references
do
  ref_id=$(echo $ref | awk -F "/" '{ print $NF }' | awk -F "_" '{ print $NF }' | sed 's|.fasta||g')
  echo $ref_id,1,$barcode,,$ref, >> samplesheet.csv
  echo $ref_id,2,$barcode,,$ref, >> samplesheet.csv
done

