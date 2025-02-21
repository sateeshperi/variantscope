process MANTA_SOMATIC {
    tag "$meta.id"
    label 'process_medium'
    label 'error_retry'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/manta:1.6.0--h9ee0642_1' :
        'biocontainers/manta:1.6.0--h9ee0642_1' }"

    input:
    tuple val(meta), path(tumorbam), path(tumorbai), path(normalbam), path(normalbai)
    path genome
    path genome_fai
    path genome_dict

    output:
    tuple val(meta), path("*.candidate_small_indels.vcf.gz")     , emit: candidate_small_indels_vcf
    tuple val(meta), path("*.candidate_small_indels.vcf.gz.tbi") , emit: candidate_small_indels_vcf_tbi
    tuple val(meta), path("*.candidate_sv.vcf.gz")               , emit: candidate_sv_vcf
    tuple val(meta), path("*.candidate_sv.vcf.gz.tbi")           , emit: candidate_sv_vcf_tbi
    tuple val(meta), path("*.diploid_sv.vcf.gz")                 , emit: diploid_sv_vcf
    tuple val(meta), path("*.diploid_sv.vcf.gz.tbi")             , emit: diploid_sv_vcf_tbi
    tuple val(meta), path("*.somatic_sv.vcf.gz")                 , emit: somatic_sv_vcf
    tuple val(meta), path("*.somatic_sv.vcf.gz.tbi")             , emit: somatic_sv_vcf_tbi
    path "versions.yml"                                          , emit: versions

    script:
    def args          = task.ext.args   ?: ''
    def prefix        = task.ext.prefix ?: "${meta.id}"
    //def options_manta = target_bed      ? "--callRegions $target_bed" : ""
    //def config_option = config          ? "--config ${config}" : ""
    """
    configManta.py \\
        --tumorBam ${tumorbam} \\
        --normalBam ${normalbam} \\
        --reference ${genome} \\
        --runDir manta 

    python manta/runWorkflow.py -m local -j ${task.cpus}

    mv manta/results/variants/candidateSmallIndels.vcf.gz \\
        ${prefix}.candidate_small_indels.vcf.gz
    mv manta/results/variants/candidateSmallIndels.vcf.gz.tbi \\
        ${prefix}.candidate_small_indels.vcf.gz.tbi
    mv manta/results/variants/candidateSV.vcf.gz \\
        ${prefix}.candidate_sv.vcf.gz
    mv manta/results/variants/candidateSV.vcf.gz.tbi \\
        ${prefix}.candidate_sv.vcf.gz.tbi
    mv manta/results/variants/diploidSV.vcf.gz \\
        ${prefix}.diploid_sv.vcf.gz
    mv manta/results/variants/diploidSV.vcf.gz.tbi \\
        ${prefix}.diploid_sv.vcf.gz.tbi
    mv manta/results/variants/somaticSV.vcf.gz \\
        ${prefix}.somatic_sv.vcf.gz
    mv manta/results/variants/somaticSV.vcf.gz.tbi \\
        ${prefix}.somatic_sv.vcf.gz.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        manta: \$(configManta.py --version)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "" | gzip > ${prefix}.candidate_small_indels.vcf.gz
    touch ${prefix}.candidate_small_indels.vcf.gz.tbi
    echo "" | gzip > ${prefix}.candidate_sv.vcf.gz
    touch ${prefix}.candidate_sv.vcf.gz.tbi
    echo "" | gzip > ${prefix}.diploid_sv.vcf.gz
    touch ${prefix}.diploid_sv.vcf.gz.tbi
    echo "" | gzip > ${prefix}.somatic_sv.vcf.gz
    touch ${prefix}.somatic_sv.vcf.gz.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        manta: \$(configManta.py --version)
    END_VERSIONS
    """
}
