process LINX_SOMATIC {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hmftools-linx:1.25--hdfd78af_0' :
        'biocontainers/hmftools-linx:1.25--hdfd78af_0' }"

    input:
    tuple val(meta), path(purple_dir)
    val genome_version
    path ensembl_path
    path known_fusion
    path driver_genes

    output:
    tuple val(meta), path('linx_somatic/'), emit: annotation_dir
    path 'versions.yml'                   , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    n_proc=\$(nproc 2>/dev/null || < /proc/cpuinfo grep '^process' -c)

    linx \\
        -Xmx${Math.round(task.memory.bytes * 0.95)} \\
        -sample ${meta.tumor_id} \\
        -sv_vcf ${purple_dir}/${meta.tumor_id}.purple.sv.vcf.gz \\
        -purple_dir ${purple_dir} \\
        -ref_genome_version ${genome_version} \\
        -ensembl_data_dir ${ensembl_path} \\
        -known_fusion_file ${known_fusion} \\
        -driver_gene_panel ${driver_genes} \\
        -output_dir linx_somatic/ \\
        -threads \${n_proc} \\
        -log_debug \\
        -write_all

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        linx: "\$(linx -version | sed 's/^.* //')"
    END_VERSIONS
    """

    stub:
    """
    mkdir linx_somatic/
    touch linx_somatic/placeholder

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        linx: "\$(linx -version | sed 's/^.* //')"
    END_VERSIONS
    """
}
