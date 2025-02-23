process GRIPSS_SOMATIC {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hmftools-gripss:2.4--hdfd78af_0':
        'biocontainers/hmftools-gripss:2.4--hdfd78af_0' }"

    input:
    tuple val(meta), path(gridss_vcf)
    val genome_ver
    path genome_fasta
    path genome_fai
    path genome_dict

    output:
    tuple val(meta), path("${meta.tumor_id}.gripss.filtered.somatic.vcf.gz"), path("${meta.tumor_id}.gripss.filtered.somatic.vcf.gz.tbi"), emit: vcf_filtered
    tuple val(meta), path("${meta.tumor_id}.gripss.somatic.vcf.gz"), path("${meta.tumor_id}.gripss.somatic.vcf.gz.tbi")  , emit: vcf_somatic
    path 'versions.yml'                                                                    , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reference_arg = meta.containsKey('normal_id') ? "-reference ${meta.normal_id}" : ''
    def output_id_arg = meta.containsKey('normal_id') ? '-output_id somatic' : ''
    """
    gripss \\
        -Xmx${Math.round(task.memory.bytes * 0.95)} \\
        -sample ${meta.tumor_id} \\
        ${reference_arg} \\
        -vcf ${gridss_vcf} \\
        -ref_genome ${genome_fasta} \\
        -ref_genome_version ${genome_ver} \\
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
    touch ${meta.tumor_id}.gripss.filtered.somatic.vcf.gz
    touch ${meta.tumor_id}.gripss.filtered.somatic.vcf.gz.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gripss: \$(gripss --version)
    END_VERSIONS
    """
}
