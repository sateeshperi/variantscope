include { AMBER  } from '../../../modules/local/amber/main'
include { COBALT } from '../../../modules/local/cobalt/main'
include { PURPLE } from '../../../modules/local/purple/main'
include { LINX_SOMATIC } from '../../../modules/local/linx/linx_somatic/main'
include { LINX_VISUALISER } from '../../../modules/local/linx/visualizer/main'

workflow CNV_CALLING {

    take:
    ch_bam
    ch_genome 
    ch_genome_fai
    ch_genome_dict
    ch_genome_version
    ch_amber_germline_sites
    ch_gc_profile
    ch_ensembl_path
    gripps_filtered_vcf
    known_fusion
    driver_genes

    main:

    ch_versions = Channel.empty()

    AMBER(
        ch_bam,
        ch_genome_version,
        ch_amber_germline_sites
    )

    ch_versions = ch_versions.mix(AMBER.out.versions.first())

    COBALT(
        ch_bam,
        ch_gc_profile
    )
    ch_versions = ch_versions.mix(COBALT.out.versions.first())


    ch_purple_input = ch_bam
        .combine(gripps_filtered_vcf, by: [0])
        .combine(AMBER.out.amber_dir, by: [0])
        .combine(COBALT.out.cobalt_dir, by: [0])

    PURPLE(
        ch_purple_input,
        ch_genome_version,
        ch_genome,
        ch_genome_fai,
        ch_genome_dict,
        ch_gc_profile,
        ch_ensembl_path
    )

    ch_versions = ch_versions.mix(PURPLE.out.versions.first())

    LINX_SOMATIC(
        PURPLE.out.purple_dir,
        ch_genome_version,
        ch_ensembl_path,
        known_fusion,
        driver_genes
    )

    ch_versions = ch_versions.mix(LINX_SOMATIC.out.versions.first())

    LINX_VISUALISER(
        LINX_SOMATIC.out.annotation_dir,
        ch_genome_version,
        ch_ensembl_path
    )

    

    emit:
    versions = ch_versions                     // channel: [ versions.yml ]
}
