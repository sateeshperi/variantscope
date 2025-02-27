include { LINX_SOMATIC    } from '../../../modules/local/linx/somatic/main'
include { LINX_VISUALISER } from '../../../modules/local/linx/visualizer/main'

workflow SV_EVENT_CALLING {

    take:
    ch_purple_dir
    ch_genome_version
    ch_ensembl_path
    ch_known_fusion
    ch_driver_genes

    main:

    ch_versions = Channel.empty()

    // LINX_SOMATIC
    LINX_SOMATIC(
        ch_purple_dir,
        ch_genome_version,
        ch_ensembl_path,
        ch_known_fusion,
        ch_driver_genes
    )

    ch_versions = ch_versions.mix(LINX_SOMATIC.out.versions.first())

    // LINX_VISUALISER
    LINX_VISUALISER(
        LINX_SOMATIC.out.annotation_dir,
        ch_genome_version,
        ch_ensembl_path
    )

    ch_versions = ch_versions.mix(LINX_VISUALISER.out.versions.first())

    emit:
    linx_plots = LINX_VISUALISER.out.plots
    versions   = ch_versions                     // channel: [ versions.yml ]
}
