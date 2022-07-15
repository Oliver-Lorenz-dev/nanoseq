process DEEPVARIANT {
    tag "$meta.id"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker.io/google/deepvariant:1.3.0' :
        'docker.io/google/deepvariant:1.3.0' }"

    input:
    tuple val(meta), path(sizes), val(is_transcripts), path(input), path(index)
    path(fasta)
    path(fai)

    output:
    tuple val(meta), path("${prefix}.vcf.gz")   ,  emit: vcf
    tuple val(meta), path("${prefix}.g.vcf.gz") ,  emit: gvcf
    path "versions.yml"                         ,  emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args ?: ''
    prefix      = task.ext.prefix ?: "${meta.id}"
    //def regions = intervals ? "--regions ${intervals}" : ""

    """
    # horrible fix for some channel issue with the refs
    rm *.fasta
    rm *.fasta.fai
    ref_id=\$(echo $input | awk -F "_" '{ print \$2 }')
    find ${workflow.projectDir}/work -name "*\${ref_id}*.fasta" -print0 | xargs -0 -I {} cp {} .
    find ${workflow.projectDir}/work -name "*\${ref_id}*.fasta.fai" -print0 | xargs -0 -I {} cp {} .
    correct_ref=\$(ls *.fasta | head -1)

    /opt/deepvariant/bin/run_deepvariant \\
        --ref=\${correct_ref} \\
        --reads=${input} \\
        --output_vcf=${prefix}.vcf.gz \\
        --output_gvcf=${prefix}.g.vcf.gz \\
        ${args} \\
        --num_shards=${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deepvariant: \$(echo \$(/opt/deepvariant/bin/run_deepvariant --version) | sed 's/^.*version //; s/ .*\$//' )
    END_VERSIONS
    """
}
