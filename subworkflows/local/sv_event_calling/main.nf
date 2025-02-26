include { LINX_SOMATIC    } from '../../../modules/local/linx/linx_somatic/main'
include { LINX_VISUALISER } from '../../../modules/local/linx/visualizer/main'

workflow SV_EVENT_CALLING {

    take:
    purple_dir
    ch_genome_version
    ch_ensembl_path
    known_fusion
    driver_genes

    main:

    ch_versions = Channel.empty()

    LINX_SOMATIC(
        purple_dir,
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

    ch_versions = ch_versions.mix(LINX_VISUALISER.out.versions.first())

    emit:
    versions = ch_versions                     // channel: [ versions.yml ]
}
