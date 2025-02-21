process AMBER {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hmftools-amber:4.0.1--hdfd78af_0' :
        'biocontainers/hmftools-amber:4.0.1--hdfd78af_0' }"

    input:
    tuple val(meta), path(tumorbam), path(tumorbai), path(normalbam), path(normalbai)
    val(version)
    path(amber_germline_sites)


    output:
    tuple val(meta), path('amber/'), emit: amber_dir
    path 'versions.yml'            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    java -jar ~/tools/amber_v4.0.jar \\
        -reference ${meta.normal_id} \\
        -reference_bam ${normalbam} \\
        -tumor ${meta.tumor_id} \\
        -tumor_bam ${tumorbam} \\
        -output_dir amber/ \\
        -threads ${task.cpus} \\
        -loci ${amber_germline_sites} \\
        -ref_genome_version ${version}


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        amber: \$(amber -version | sed 's/^.* //')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p amber/
    touch amber/placeholder

    echo -e '${task.process}:\\n  stub: noversions\\n' > versions.yml
    """
}
