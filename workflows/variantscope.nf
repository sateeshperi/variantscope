/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_variantscope_pipeline'
include {BAM_VCF_SV_CALLING} from '../subworkflows/local/bam_vcf_sv_calling/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOME PARAMETER VALUES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// params.fasta         = getGenomeAttribute('fasta')
// params.fasta_index   = getGenomeAttribute('fasta_index')
// params.bwa_index     = getGenomeAttribute('bwa')

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow VARIANTSCOPE {

    take:
    samplesheet // channel: samplesheet read in from --input
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
            }
        }
        .filter { it != null }


    //ch_bam.view()

   ch_bam|BAM_VCF_SV_CALLING


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
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
