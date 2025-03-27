process BCFTOOLS_INDEX {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.20--h8b25389_0':
        'biocontainers/bcftools:1.20--h8b25389_0' }"

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("*.bgzip.vcf.gz")         , emit: vcf
    tuple val(meta), path("*.csi"), optional:true   , emit: csi
    tuple val(meta), path("*.tbi"), optional:true   , emit: tbi
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    n_proc=\$(nproc 2>/dev/null || < /proc/cpuinfo grep '^process' -c)

    gzip -cdf \\
        $vcf \\
        > ${prefix}.bgzip.vcf
    
    bgzip \\
        ${prefix}.bgzip.vcf

    bcftools \\
        index \\
        $args \\
        --threads \${n_proc} \\
        ${prefix}.bgzip.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def extension = args.contains("--tbi") || args.contains("-t") ? "tbi" :
                    "csi"
    """
    touch ${vcf}.${extension}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}
