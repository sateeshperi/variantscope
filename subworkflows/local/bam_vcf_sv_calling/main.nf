include { GRIDSS_GRIDSS } from '../modules/nf-core/gridss/gridss/main'

workflow BAM_VCF_SV_CALLING {

    take:
    ch_bam // channel: [ val(meta), [ bam ] ]

    main:

    ch_versions = Channel.empty()

    GRIDSS_GRIDSS ( ch_bam )
    ch_versions = ch_versions.mix(GRIDSS_GRIDSS.out.versions.first())

    GRIPSS_SOMATIC ( GRIDSS_GRIDSS.out.vcf )
    ch_versions = ch_versions.mix(GRIPSS_SOMATIC.out.versions.first())

    emit:
    bam      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

