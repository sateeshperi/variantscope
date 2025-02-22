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
    gripps_filtered_vcf

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

    // PURPLE
    // ch_purple_input = Channel.empty()
    //     .mix(ch_bam)
    //     .combine(gripps_filtered_vcf, by: [0])
    //     .map { bam_meta, bam_paths, vcf_paths ->
    //         [
    //             bam_meta,            // meta map
    //             bam_paths[1],        // tumorbam
    //             bam_paths[2],        // tumorbai
    //             bam_paths[3],        // normalbam
    //             bam_paths[4],        // normalbai
    //             vcf_paths[1],        // gripps_filtered_vcf
    //             vcf_paths[2]         // gripps_filtered_vcf_tbi
    //         ]
    //     }

    // PURPLE(
    //     ch_purple_input,
    //     AMBER.out.amber_dir,
    //     COBALT.out.cobalt_dir,
    //     ch_genome_version,
    //     ch_genome,
    //     ch_genome_fai,
    //     ch_genome_dict,
    //     ch_gc_profile,
    //     ch_ensembl_path
    // )

    // ch_versions = ch_versions.mix(PURPLE.out.versions.first())

    emit:
    versions = ch_versions                     // channel: [ versions.yml ]
}
