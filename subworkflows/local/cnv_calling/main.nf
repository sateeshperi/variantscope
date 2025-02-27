include { AMBER  } from '../../../modules/local/amber/main'
include { COBALT } from '../../../modules/local/cobalt/main'
include { PURPLE } from '../../../modules/local/purple/main'

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
    ch_gripps_filtered_vcf

    main:

    ch_versions = Channel.empty()

    // AMBER
    AMBER(
        ch_bam,
        ch_genome_version,
        ch_amber_germline_sites
    )

    ch_versions = ch_versions.mix(AMBER.out.versions.first())

    // COBALT
    COBALT(
        ch_bam,
        ch_gc_profile
    )
    
    ch_versions = ch_versions.mix(COBALT.out.versions.first())

    // PURPLE
    ch_purple_input = ch_bam
                        .combine(ch_gripps_filtered_vcf, by: 0)
                        .combine(AMBER.out.amber_dir, by: 0)
                        .combine(COBALT.out.cobalt_dir, by: 0)

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

    emit:
    purple_dir = PURPLE.out.purple_dir
    versions   = ch_versions                     // channel: [ versions.yml ]
}
