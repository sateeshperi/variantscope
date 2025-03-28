process GRIDSS {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gridss:2.13.2--h270b39a_0':
        'biocontainers/gridss:2.13.2--h270b39a_0' }"

    input:
    tuple val(meta), path(tumorbam), path(tumorbai), path(normalbam), path(normalbai)
    path genome
    path genome_fai
    path genome_dict

    output:
    tuple val(meta), path("${meta.id}_gridss.vcf") , emit: vcf
    path "versions.yml"                            , emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    n_proc=\$(nproc 2>/dev/null || < /proc/cpuinfo grep '^process' -c)

    gridss \\
        --reference ${genome} \\
        --threads \${n_proc} \\
        --jvmheap ${task.memory.toGiga() - 1}g \\
        --otherjvmheap ${task.memory.toGiga() - 1}g \\
        ${tumorbam} ${normalbam} \\
        -o ${prefix}_gridss.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gridss: "2.13.2"
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_gridss.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gridss: "2.13.2"
    END_VERSIONS
    """
}

