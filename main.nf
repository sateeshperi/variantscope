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
ch_genome               = params.genome               ?: "${projectDir}/assets/references/hg38.fa"
ch_genome_fai           = params.genome_fai           ?: "${projectDir}/assets/references/hg38.fa.fai"
ch_genome_dict          = params.genome_dict          ?: "${projectDir}/assets/references/hg38.dict"
ch_genome_version       = params.genome_version       ?: '38'
ch_dbsnp                = params.dbsnp                ?: "${projectDir}/assets/references/dbsnp_138.hg38.vcf.gz"
ch_regions              = params.regions              ?: "${projectDir}/assets/references/regions.bed"
ch_amber_germline_sites = params.amber_germline_sites ?: "${projectDir}/assets/references/AmberGermlineSites.38.tsv.gz"
ch_gc_profile           = params.gc_profile           ?: "${projectDir}/assets/references/GC_profile.1000bp.38.cnp"
ch_ensembl_path         = params.ensembl_path         ?: "${projectDir}/assets/references/ensembl"
ch_bwa_index            = params.bwa_index            ?: "${projectDir}/assets/references"
ch_unmap_regions        = params.unmap_regions        ?: "${projectDir}/assets/references/unmap_regions.38.tsv"
ch_known_fusion         = params.known_fusion         ?: "${projectDir}/assets/references/known_fusions.txt"
ch_ensembl_data         = params.ensembl_data         ?: "${projectDir}/assets/references/ensembl_data"
ch_driver_genes         = params.driver_genes         ?: "${projectDir}/assets/references/driver_genes.txt"

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
