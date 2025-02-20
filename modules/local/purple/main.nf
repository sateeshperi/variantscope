process PURPLE {
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hmftools-purple:4.0.2--hdfd78af_0' :
        'biocontainers/hmftools-purple:4.0.2--hdfd78af_0' }"

    input:
    tuple val(meta), path(tumorbam), path(tumorbai), path(normalbam), path(normalbai), path(amber),path(cobalt), path(gripps_filtered_vcf)
    val(version)
    path(genome)
    path(genome_fai)
    path(genome_dict)
    path(gc_profile)
    path(ensembl_path)

    output:
    tuple val(meta), path('purple/'), emit: purple_dir
    path 'versions.yml'             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """

    java -jar ~/tools/purple_v4.0.jar \\
        -Xmx${Math.round(task.memory.bytes * 0.95)}
        -reference ${meta.normal_id} \\
        -tumor ${meta.tumor_id} \\
        -amber ${amber}/${meta.tumor_id} \\
        -cobalt ${cobalt}/${meta.tumor_id} \\
        -gc_profile ${gc_profile} \\
        -ref_genome ${genome} \\
        -ref_genome_version ${version} \\
        -ensembl_data_dir ${ensembl_path} \\
        -somatic_sv_vcf ${gripps_filtered_vcf} \\
        -circos \$(which circos)  \\
        -output_dir purple/


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        purple: \$(purple -version | sed 's/^.* //')
    END_VERSIONS
    """

    stub:
    """
    mkdir purple/

    echo -e '${task.process}:\\n  stub: noversions\\n' > versions.yml
    """
}
