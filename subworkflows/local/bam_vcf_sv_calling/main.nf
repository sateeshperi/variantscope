include { GRIDSS         } from '../../../modules/nf-core/gridss/gridss/main'
include { GRIPSS_SOMATIC } from '../../../modules/local/gripss/somatic/main'
include { SVABA          } from '../../../modules/nf-core/svaba/main'
include { MANTA_SOMATIC  } from '../../../modules/nf-core/manta/somatic/main'

workflow BAM_VCF_SV_CALLING {

    take:
    ch_bam // tuple with tumor and normal bam files
    ch_genome 
    ch_genome_fai
    ch_genome_dict
    ch_genome_version
    ch_dbsnp
    ch_regions
    ch_bwa_index

    main:

    ch_versions = Channel.empty()

    // GRIDSS
    GRIDSS(
        ch_bam,
        ch_genome,
        ch_genome_fai,
        ch_genome_dict
    )

    ch_versions = ch_versions.mix(GRIDSS.out.versions)

    // GRIPSS
    GRIPSS_SOMATIC(
        GRIDSS.out.vcf,
        ch_genome_version,
        ch_genome,
        ch_genome_fai,
        ch_genome_dict
    )

    ch_versions = ch_versions.mix(GRIPSS_SOMATIC.out.versions)

    // SVABA
    SVABA(
        ch_bam,
        ch_genome,
        ch_genome_fai,
        ch_genome_dict,
        ch_dbsnp,
        ch_regions,
        ch_bwa_index
    )

    ch_versions = ch_versions.mix(SVABA.out.versions)

    // MANTA
    // MANTA_SOMATIC(
    //     ch_bam,
    //     ch_genome,
    //     ch_genome_fai,
    //     ch_genome_dict
    // )

    // ch_versions = ch_versions.mix(MANTA_SOMATIC.out.versions)

    emit:
    vcf_filtered = GRIPSS_SOMATIC.out.vcf_filtered // channel: [ [ meta ], vcf ]
    vcf_somatic  = GRIPSS_SOMATIC.out.vcf_somatic  // channel: [ [ meta ], vcf ]
    versions     = ch_versions                     // channel: [ versions.yml ]
}
