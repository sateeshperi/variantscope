/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_variantscope_pipeline'
include { BAM_VCF_SV_CALLING     } from '../subworkflows/local/bam_vcf_sv_calling/main'
include { CNV_CALLING            } from '../subworkflows/local/cnv_calling/main'
include { SV_EVENT_CALLING       } from '../subworkflows/local/sv_event_calling/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow VARIANTSCOPE {

    take:
    samplesheet // channel: samplesheet read in from --input
    ch_genome
    ch_genome_fai
    ch_genome_dict
    ch_genome_version
    ch_amber_germline_sites
    ch_gc_profile
    ch_ensembl_path
    ch_bwa_index
    ch_known_fusion
    ch_driver_genes
    ch_dbsnp

    main:

    ch_versions = Channel.empty()

    // Read the samplesheet CSV into a channel of maps
    ch_bam = Channel.fromPath(params.input)
                    .splitCsv(header: true)
                    .map { row -> tuple(row.subject_id, row) }
                    .groupTuple()
                    .map { subject_id, rows ->
                        def tumor = rows.find { it.sample_type == 'tumor' }
                        def normal = rows.find { it.sample_type == 'normal' }
                        if (tumor && normal) {
                            [
                                [id: subject_id,
                                tumor_id: tumor.sample_id,
                                normal_id: normal.sample_id],  // meta
                                file(tumor.filepath),   // tumor bam
                                file(tumor.indexpath),  // tumor bai
                                file(normal.filepath),  // normal bam
                                file(normal.indexpath)  // normal bai
                            ]
                        } else {
                            error "Subject ID ${subject_id} does not have both 'tumor' and 'normal' sample types. Please fix the input samplesheet"
                        }
                    }
                    .filter { it != null }

    // SV calling Subworkflow
    BAM_VCF_SV_CALLING(
        ch_bam,
        ch_genome,
        ch_genome_fai,
        ch_genome_dict ?: [],
        ch_genome_version ?: [],
        ch_bwa_index ?: [],
        ch_dbsnp ?: []
    )

    // ch_versions = ch_versions.mix(BAM_VCF_SV_CALLING.out.versions)

    // CNV calling Subworkflow
    // CNV_CALLING(
    //     ch_bam,
    //     ch_genome,
    //     ch_genome_fai,
    //     ch_genome_dict,
    //     ch_genome_version,
    //     ch_amber_germline_sites,
    //     ch_gc_profile,
    //     ch_ensembl_path,
    //     BAM_VCF_SV_CALLING.out.vcf_filtered
    // )

    // ch_versions = ch_versions.mix(CNV_CALLING.out.versions)

    // SV Event calling Subworkflow
    // SV_EVENT_CALLING(
    //     CNV_CALLING.out.purple_dir,
    //     ch_genome_version,
    //     ch_ensembl_path,
    //     ch_known_fusion,
    //     ch_driver_genes
    // )

    // ch_versions = ch_versions.mix(SV_EVENT_CALLING.out.versions)

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'variantscope_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    emit:
    versions = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
