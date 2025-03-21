include { GRIDSS } from '../../../modules/nf-core/gridss/gridss/main'
include { GRIPSS_SOMATIC } from '../../../modules/local/gripss/somatic/main'

include { SVABA } from '../../../modules/nf-core/svaba/main'
include { BCFTOOLS_INDEX } from '../../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_CONCAT as CONCATSVABA } from '../../../modules/nf-core/bcftools/concat/main'

include { SPLIT_BAM } from '../../../modules/local/split_bam/main'
include { MANTA_SOMATIC } from '../../../modules/nf-core/manta/somatic/main'
include { BCFTOOLS_CONCAT as CONCATMANTA } from '../../../modules/nf-core/bcftools/concat/main'

workflow BAM_VCF_SV_CALLING {
    take:
    ch_bam // tuple with tumor and normal bam files
    ch_genome
    ch_genome_fai
    ch_genome_dict
    ch_genome_version
    ch_bwa_index
    ch_dbsnp
    val_num_chunks          // Integer: Number of chunks to split the BAM files into
    val_chunk_overlap       // Integer: Percentage of overlap between chunks, e.g. 10 = 10% overlap

    main:

    ch_versions = Channel.empty()

    // GRIDSS
    GRIDSS(
        ch_bam,
        ch_genome,
        ch_genome_fai,
        ch_genome_dict
    )

    ch_versions = ch_versions.mix(GRIDSS.out.versions.first())

    // GRIPSS
    GRIPSS_SOMATIC(
        GRIDSS.out.vcf,
        ch_genome_version,
        ch_genome,
        ch_genome_fai,
        ch_genome_dict
    )

    ch_versions = ch_versions.mix(GRIPSS_SOMATIC.out.versions.first())

    // MODULE: SPLIT_BAM
    SPLIT_BAM (
        ch_bam,
        val_num_chunks,
        val_chunk_overlap
    )

    ch_split_bam_output = SPLIT_BAM.out.t_bam.flatMap { meta, files -> files.collect { [ meta, it ] } }.map { addChunkID(it) }
        .join( SPLIT_BAM.out.t_bai.flatMap { meta, files -> files.collect { [ meta, it ] } }.map { addChunkID(it) } )
        .join( SPLIT_BAM.out.n_bam.flatMap { meta, files -> files.collect { [ meta, it ] } }.map { addChunkID(it) } )
        .join( SPLIT_BAM.out.n_bai.flatMap { meta, files -> files.collect { [ meta, it ] } }.map { addChunkID(it) } )
        .filter { _meta, t_bam, _t_bai, n_bam, _n_bai ->
            t_bam.size() > 1048576 && n_bam.size() > 1048576
        } // Both BAMs should be greater than 1 MB otherwise MANTA generally fails


    ch_versions = ch_versions.mix(SPLIT_BAM.out.versions.first())

    // SVABA
    SVABA(
        ch_split_bam_output,
        ch_genome,
        ch_genome_fai,
        ch_genome_dict,
        ch_dbsnp,
        ch_bwa_index
    )

    ch_versions = ch_versions.mix(SVABA.out.versions.first())

    // MODULE: BCFTOOLS_INDEX
    BCFTOOLS_INDEX ( SVABA.out.sv )

    ch_versions = ch_versions.mix(BCFTOOLS_INDEX.out.versions.first())

    // MODULE: CONCATSVABA
    ch_concat_svaba_input = SVABA.out.sv.join(BCFTOOLS_INDEX.out.tbi)
        .map { meta, vcf, tbi ->
            [ meta + [ id: "${meta.subject_id}" ], vcf, tbi ]
        }
        .groupTuple()
        .map { meta, vcfs, tbis ->
            [ meta, vcfs.toSorted(), tbis.toSorted() ]
        }

    CONCATSVABA(
        ch_concat_svaba_input
    )

    ch_versions = ch_versions.mix(CONCATSVABA.out.versions.first())

    // MANTA
    MANTA_SOMATIC(
        ch_split_bam_output,
        ch_genome,
        ch_genome_fai,
        ch_genome_dict,
    )

    ch_versions = ch_versions.mix(MANTA_SOMATIC.out.versions.first())

    // MODULE: CONCAT_MANTA_VCF
    ch_concat_vcf_input = MANTA_SOMATIC.out.somatic_sv_vcf.join(MANTA_SOMATIC.out.somatic_sv_vcf_tbi)
        .map { meta, vcf, tbi ->
            [ meta + [ id: "${meta.subject_id}.somatic_sv" ], vcf, tbi ]
        }
        .groupTuple()
        .map { meta, vcfs, tbis ->
            [ meta, vcfs.toSorted(), tbis.toSorted() ]
        }

    CONCATMANTA(
        ch_concat_vcf_input
    )

    ch_versions = ch_versions.mix(CONCATMANTA.out.versions.first())

    emit:
    vcf_filtered = GRIPSS_SOMATIC.out.vcf_filtered
    vcf_somatic = GRIPSS_SOMATIC.out.vcf_somatic
    versions = ch_versions // channel: [ versions.yml ]
}

def addChunkID(meta, dataFile) {
    def chunk_id = (dataFile.name =~ /chunk(.*?)\.(tumor|normal)/)[0][1]

    [ meta + [ id: "${meta.id}_chunk$chunk_id", subject_id: "${meta.id}" ], dataFile ]
}
