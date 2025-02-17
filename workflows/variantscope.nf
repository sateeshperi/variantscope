/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_variantscope_pipeline'

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
    ch_samplesheet = Channel.fromPath(params.input)
    .splitCsv(header: true)
    // Create a new grouping key by removing ".tumor" / ".normal" from sample_id
    .map { row ->
        def baseSample = row.sample_id.replaceAll(/(\.tumor|\.normal)$/, '')
        tuple(
            baseSample,
            [
                group_id      : row.group_id,
                subject_id    : row.subject_id,
                sample_id     : row.sample_id,
                sample_type   : row.sample_type,
                sequence_type : row.sequence_type,
                filetype      : row.filetype,
                filepath      : row.filepath,
                indexpath     : row.indexpath
            ]
        )
    }
    .groupTuple()
    // Convert grouped rows into a structure containing both tumor and normal info
    .map { baseSampleId, rows ->
        def tumor  = rows.find { it.sample_type == 'tumor' }
        def normal = rows.find { it.sample_type == 'normal' }
        [
            sample_id: baseSampleId,
            tumor    : tumor,
            normal   : normal
        ]
    }

    ch_samplesheet.view()

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
