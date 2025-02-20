include { GRIDSS        } from '../../../modules/nf-core/gridss/gridss/main'
include { MANTA_SOMATIC } from '../../../modules/nf-core/manta/somatic/main'  
include { SVABA         } from '../../../modules/nf-core/svaba/main'  
include { GRIPSS_SOMATIC } from '../../../modules/local/gripss/somatic/main'

params.genome = params.genome ?: "${projectDir}/assets/references/hg38.fa"
params.genome_fai = params.genome_fai ?: "${projectDir}/assets/references/hg38.fa.fai"
params.genome_dict = params.genome_dict ?: "${projectDir}/assets/references/hg38.dict"

    genome                  = Channel.of(file(params.genome))
    genome_fai              = Channel.of(file(params.genome_fai))
    genome_dict             = Channel.of(file(params.genome_dict))

workflow BAM_VCF_SV_CALLING {

    take:
    ch_bam 

    main:

    ch_versions = Channel.empty()

    GRIDSS(ch_bam
        .combine(genome)
        .combine(genome_fai)
        .combine(genome_dict)
    )

    ch_versions = ch_versions.mix(GRIDSS.out.versions.first())


    GRIPSS_SOMATIC(GRIDSS.out.vcf
        .combine(Channel.of('hg38'))  // placeholder, this should be a version in a config file
        .combine(genome)
        .combine(genome_fai)
        .combine(genome_dict)
    )
    ch_versions = ch_versions.mix(GRIPSS_SOMATIC.out.versions.first())
/*
    emit:
    bam      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]
*/
    versions = ch_versions                     // channel: [ versions.yml ]
}

