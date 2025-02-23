process COBALT {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hmftools-cobalt:1.16--hdfd78af_0' :
        'biocontainers/hmftools-cobalt:1.16--hdfd78af_0' }"

    input:
    tuple val(meta), path(tumorbam), path(tumorbai), path(normalbam), path(normalbai)
    path gc_profile

    output:
    tuple val(meta), path("cobalt"), emit: cobalt_dir
    path 'versions.yml'             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    cobalt \\
        -Xmx${Math.round(task.memory.bytes * 0.95)} \\
        -reference ${meta.normal_id} \\
        -reference_bam ${normalbam} \\
        -tumor ${meta.tumor_id} \\
        -tumor_bam ${tumorbam} \\
        -threads ${task.cpus} \\
        -gc_profile ${gc_profile} \\
        -output_dir cobalt/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cobalt: \$(cobalt -version | sed 's/^.* //')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p cobalt
    touch cobalt/placeholder

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cobalt: \$(cobalt -version | sed 's/^.* //')
    END_VERSIONS
    """
}
