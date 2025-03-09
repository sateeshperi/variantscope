process SPLIT_BAM {
    tag "${meta.id}"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    input:
    tuple val(meta), path(input), path(index)

    output:
    tuple val(meta), path("*.split.bam")        , emit: bam
    tuple val(meta), path("*.split.bam.bai")    , emit: bai
    path  "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "$meta.id"
    """
    samtools idxstats $input | cut -f1 | grep -v '*' | while read chr; do
        samtools \\
            view \\
            -b \\
            $args \\
            --threads ${task.cpus-1} \\
            $input \\
            "\$chr" \\
            > "${prefix}.\${chr}.split.bam"
    done

    for bam in *.split.bam; do
        samtools \\
            index \\
            -@ ${task.cpus-1} \\
            $args2 \\
            "\$bam"
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "$meta.id"
    """
    touch ${prefix}.chr1.split.bam
    touch ${prefix}.chr1.split.bam.bai

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
