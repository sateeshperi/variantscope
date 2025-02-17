process GRIPSS_SOMATIC {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hmftools-gripss:2.4--hdfd78af_0':
        'biocontainers/hmftools-gripss:2.4--hdfd78af_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    gripss \\
        $args \\
        -@ $task.cpus \\
        -o ${prefix}.bam \\
        $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gripss: \$(gripss --version)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gripss: \$(gripss --version)
    END_VERSIONS
    """
}
