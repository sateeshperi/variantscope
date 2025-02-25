process LINX_VISUALISER {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hmftools-linx:1.25--hdfd78af_0' :
        'biocontainers/hmftools-linx:1.25--hdfd78af_0' }"

    input:
    tuple val(meta), path(linx_annotation_dir)
    val genome_version
    path ensembl_path
    output:
    tuple val(meta), path('plots/'), emit: plots
    path 'versions.yml'            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    """
    mkdir -p plots/


    linx \\
        -Xmx${Math.round(task.memory.bytes * 0.95)} \\
        com.hartwig.hmftools.linx.visualiser.SvVisualiser \\
        -sample ${meta.tumor_id} \\
        -vis_file_dir ${linx_annotation_dir} \\
        -ref_genome_version ${genome_version} \\
        -ensembl_data_dir ${ensembl_path} \\
        -circos \$(which circos) \\
        -threads ${task.cpus} \\
        -plot_out plots/all/ \\
        -data_out data/all/



    # Create placeholders to force FusionFS to create parent plot directory on S3
    if [[ \$(ls plots/ | wc -l) -eq 0 ]]; then
        touch plots/.keep;
    fi;

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        linx: \$(linx -version | sed 's/^.* //')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p plots/{all}/
    touch plots/{all}/placeholder

    echo -e '${task.process}:\n  stub: noversions\n' > versions.yml
    """
}
