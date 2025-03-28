
process SVABA {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/svaba:1.1.0--h7d7f7ad_2':
        'biocontainers/svaba:1.1.0--h7d7f7ad_2' }"

    input:
    tuple val(meta), path(tumorbam), path(tumorbai), path(normalbam), path(normalbai)
    path genome
    path genome_fai
    path genome_dict
    path dbsnp
    path bwa_index

    output:
    tuple val(meta), path("*.svaba.sv.vcf.gz")                        , emit: sv                    , optional: true
    tuple val(meta), path("*.svaba.indel.vcf.gz")                     , emit: indel                 , optional: true
    tuple val(meta), path("*.svaba.germline.indel.vcf.gz")            , emit: germ_indel            , optional: true
    tuple val(meta), path("*.svaba.germline.sv.vcf.gz")               , emit: germ_sv               , optional: true
    tuple val(meta), path("*.svaba.somatic.indel.vcf.gz")             , emit: som_indel             , optional: true
    tuple val(meta), path("*.svaba.somatic.sv.vcf.gz")                , emit: som_sv                , optional: true
    tuple val(meta), path("*.svaba.unfiltered.sv.vcf.gz")             , emit: unfiltered_sv         , optional: true
    tuple val(meta), path("*.svaba.unfiltered.indel.vcf.gz")          , emit: unfiltered_indel      , optional: true
    tuple val(meta), path("*.svaba.unfiltered.germline.indel.vcf.gz") , emit: unfiltered_germ_indel , optional: true
    tuple val(meta), path("*.svaba.unfiltered.germline.sv.vcf.gz")    , emit: unfiltered_germ_sv    , optional: true
    tuple val(meta), path("*.svaba.unfiltered.somatic.indel.vcf.gz")  , emit: unfiltered_som_indel  , optional: true
    tuple val(meta), path("*.svaba.unfiltered.somatic.sv.vcf.gz")     , emit: unfiltered_som_sv     , optional: true
    tuple val(meta), path("*.bps.txt.gz")                             , emit: raw_calls
    tuple val(meta), path("*.discordants.txt.gz")                     , emit: discordants           , optional: true
    tuple val(meta), path("*.log")                                    , emit: log
    path "versions.yml"                                               , emit: versions

    script:
    def args    = task.ext.args   ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def bamlist = normalbam       ? "-t ${tumorbam} -n ${normalbam}" : "-t ${tumorbam}"
    def dbsnp   = dbsnp           ? "--dbsnp-vcf ${dbsnp}"           : ""
    def bwa     = bwa_index       ? "cp -s ${bwa_index}/*38* ."      : ""
    def id_subj = "${meta.id}".tokenize('_chunk')[0]
    """
    n_proc=\$(nproc 2>/dev/null || < /proc/cpuinfo grep '^process' -c)

    ${bwa}

    svaba run \\
        ${bamlist} \\
        --threads \${n_proc} \\
        ${dbsnp} \\
        --id-string ${meta.id} \\
        --reference-genome ${genome} \\
        --g-zip

    gzip -d \\
        ${meta.id}.svaba.somatic.sv.vcf.gz

    sed -i 's|${tumorbam}|${id_subj}_tumor|g' ${meta.id}.svaba.somatic.sv.vcf
    sed -i 's|${normalbam}|${id_subj}_normal|g' ${meta.id}.svaba.somatic.sv.vcf

    gzip \\
        ${meta.id}.svaba.somatic.sv.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        svaba: "\$(echo \$(svaba --version 2>&1) | sed 's/[^0-9.]*\\([0-9.]*\\).*/\\1/' )"
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bps.txt.gz
    touch ${prefix}.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        svaba: "\$(echo \$(svaba --version 2>&1) | sed 's/[^0-9.]*\\([0-9.]*\\).*/\\1/' )"
    END_VERSIONS
    """
}
