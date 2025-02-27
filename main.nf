#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SowpatiLab/variantscope
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/SowpatiLab/variantscope
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { VARIANTSCOPE            } from './workflows/variantscope'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_variantscope_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_variantscope_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOME PARAMETER VALUES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_genome               = params.genome               ? Channel.of(file(params.genome, checkIfExists: true))               : Channel.empty()
ch_genome_fai           = params.genome_fai           ? Channel.of(file(params.genome_fai, checkIfExists: true))           : Channel.empty()
ch_genome_dict          = params.genome_dict          ? Channel.of(file(params.genome_dict, checkIfExists: true))          : Channel.empty()
ch_genome_version       = params.genome_version       ? Channel.value(params.genome_version)                               : Channel.empty()
ch_dbsnp                = params.dbsnp                ? Channel.of(file(params.dbsnp, checkIfExists: true))                : Channel.empty()
ch_regions              = params.regions              ? Channel.of(file(params.regions, checkIfExists: true))              : Channel.empty()
ch_amber_germline_sites = params.amber_germline_sites ? Channel.of(file(params.amber_germline_sites, checkIfExists: true)) : Channel.empty()
ch_gc_profile           = params.gc_profile           ? Channel.of(file(params.gc_profile, checkIfExists: true))           : Channel.empty()
ch_ensembl_path         = params.ensembl_path         ? Channel.of(file(params.ensembl_path, checkIfExists: true))         : Channel.empty()
ch_bwa_index            = params.bwa_index            ? Channel.of(file(params.bwa_index, checkIfExists: true))            : Channel.empty()
ch_unmap_regions        = params.unmap_regions        ? Channel.of(file(params.unmap_regions, checkIfExists: true))        : Channel.empty()
ch_known_fusion         = params.known_fusion         ? Channel.of(file(params.known_fusion, checkIfExists: true))         : Channel.empty()
ch_ensembl_data         = params.ensembl_data         ? Channel.of(file(params.ensembl_data, checkIfExists: true))         : Channel.empty()
ch_driver_genes         = params.driver_genes         ? Channel.of(file(params.driver_genes, checkIfExists: true))         : Channel.empty()

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow SOWPATILAB_VARIANTSCOPE {

    take:
    samplesheet // channel: samplesheet read in from --input

    main:

    //
    // WORKFLOW: Run pipeline
    //
    VARIANTSCOPE (
        samplesheet,
        ch_genome,    
        ch_genome_fai,
        ch_genome_dict,
        ch_genome_version,
        ch_dbsnp,
        ch_regions,
        ch_amber_germline_sites,
        ch_gc_profile,    
        ch_ensembl_path,
        ch_bwa_index,
        ch_driver_genes,
        ch_known_fusion
    )
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.input
    )

    //
    // WORKFLOW: Run main workflow
    //
    SOWPATILAB_VARIANTSCOPE (
        PIPELINE_INITIALISATION.out.samplesheet
    )
    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION (
        params.outdir,
        params.monochrome_logs,
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
