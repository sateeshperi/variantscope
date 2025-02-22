process GRIPSS_SOMATIC {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hmftools-gripss:2.4--hdfd78af_0':
        'biocontainers/hmftools-gripss:2.4--hdfd78af_0' }"

    input:
    tuple val(meta), path(gridss_vcf)
    val version
    path fasta
    path genome_fai
    path genome_dict

    output:
    tuple val(meta), path("${meta.tumor_id}.gripss.somatic.vcf.gz"), path("${meta.tumor_id}.gripss.somatic.vcf.gz.tbi")   , emit: vcf
    tuple val(meta), path("${meta.tumor_id}.gripss.filtered.vcf.gz"), path("${meta.tumor_id}.gripss.filtered.vcf.gz.tbi") , emit: filtered_vcf
    path "versions.yml"                                                                                                   , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    gripss \\
        -Xmx${Math.round(task.memory.bytes * 0.95)} \\
        -sample ${meta.tumor_id} \\
        ${reference_arg} \\
        -vcf ${gridss_vcf} \\
        -ref_genome ${fasta} \\
        -ref_genome_version ${version} \\
        ${output_id_arg} \\
        -output_dir ./

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gripss: \$(gripss --version)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${meta.tumor_id}.gripss.somatic.vcf.gz
    touch ${meta.tumor_id}.gripss.somatic.vcf.gz.tbi
    touch ${meta.tumor_id}.gripss.filtered.vcf.gz
    touch ${meta.tumor_id}.gripss.filtered.vcf.gz.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gripss: \$(gripss --version)
    END_VERSIONS
    """
}
