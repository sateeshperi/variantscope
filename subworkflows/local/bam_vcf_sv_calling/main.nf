include { GRIDSS        } from '../../../modules/nf-core/gridss/gridss/main'
include { MANTA_SOMATIC } from '../../../modules/nf-core/manta/somatic/main'
include { SVABA         } from '../../../modules/nf-core/svaba/main'
include { GRIPSS_SOMATIC } from '../../../modules/local/gripss/somatic/main'

params.genome         = params.genome         ?: "${projectDir}/assets/references/hg38.fa"
params.genome_fai     = params.genome_fai     ?: "${projectDir}/assets/references/hg38.fa.fai"
params.genome_dict    = params.genome_dict    ?: "${projectDir}/assets/references/hg38.dict"
params.genome_version = params.genome_version ?: 'hg38'

workflow BAM_VCF_SV_CALLING {

    take:
    ch_bam // tuple with tumor and normal bam files

    main:

    ch_versions = Channel.empty()

    // GRIDSS
    GRIDSS(
        ch_bam,
        params.genome,
        params.genome_fai,
        params.genome_dict
    )

    ch_versions = ch_versions.mix(GRIDSS.out.versions.first())

    // GRIPSS 
    GRIPSS_SOMATIC(
        GRIDSS.out.vcf,
        params.genome_version,  // placeholder, this should be a version in a config file
        params.genome,
        params.genome_fai,
        params.genome_dict
    )

    // MANTA
    MANTA_SOMATIC(ch_bam,
        params.genome,
        params.genome_fai,
        params.genome_dict
    )

    ch_versions = ch_versions.mix(GRIPSS_SOMATIC.out.versions.first())

    emit:
    gripps_filtered_vcf = GRIPSS_SOMATIC.out.filtered_vcf // channel: [ versions.yml ]
    versions            = ch_versions                     // channel: [ versions.yml ]
}

