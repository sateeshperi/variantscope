include { GRIDSS } from '../../../modules/nf-core/gridss/gridss/main'
include { GRIPSS_SOMATIC } from '../../../modules/local/gripss/somatic/main'

include { SVABA } from '../../../modules/nf-core/svaba/main'
include { BCFTOOLS_INDEX } from '../../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_CONCAT as CONCAT_SVABA_VCF } from '../../../modules/nf-core/bcftools/concat/main'

include { SPLIT_BAM } from '../../../modules/local/split_bam/main'
include { MANTA_SOMATIC } from '../../../modules/nf-core/manta/somatic/main'
include { BCFTOOLS_CONCAT as CONCAT_MANTA_VCF } from '../../../modules/nf-core/bcftools/concat/main'

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
    ch_split_bam_input = ch_bam.map { meta, t_bam, t_bai, _n_bam, _n_bai ->
            [ meta + [ subject_id: meta.id, id: meta.tumor_id, is_tumor: true ], t_bam, t_bai ]
        }.mix(
            ch_bam.map { meta, _t_bam, _t_bai, n_bam, n_bai ->
                [ meta + [ subject_id: meta.id, id: meta.normal_id, is_tumor: false ], n_bam, n_bai ]
            }
        )

    SPLIT_BAM (
        ch_split_bam_input,
        val_num_chunks,
        val_chunk_overlap
    )

    ch_split_bam_output = SPLIT_BAM.out.bam.join(SPLIT_BAM.out.bai)
        .flatMap { meta, bams, bais ->
            bams.withIndex().collect { bam, i ->
                [ meta, bam, bais[i] ]
            }
        }
        .map { meta, bam, bai ->
            def contig_id = bam.name.tokenize('.')[-3]

            [ meta + [ id: "${meta.subject_id}_${contig_id}" ], bam, bai ]

        }.branch { meta, _bam, _bai ->
            tumor: meta.is_tumor
            normal: ! meta.is_tumor
        }

    ch_caller_input = ch_split_bam_output.tumor.map { meta, bam, bai ->
            [ [ id: meta.id, tumor_id:meta.tumor_id, normal_id:meta.normal_id, subject_id:meta.subject_id, ], bam, bai ]
        }.join(
            ch_split_bam_output.normal.map { meta, bam, bai ->
                [ [ id: meta.id, tumor_id:meta.tumor_id, normal_id:meta.normal_id, subject_id:meta.subject_id, ], bam, bai ]
            }
        )
        .filter { _meta, t_bam, _t_bai, n_bam, _n_bai ->
            t_bam.size() > 1048576 && n_bam.size() > 1048576
        } // Both BAMs should be greater than 1 MB otherwise MANTA generally fails


    ch_versions = ch_versions.mix(SPLIT_BAM.out.versions.first())

    // SVABA
    SVABA(
        ch_caller_input,
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

    // MODULE: CONCAT_SVABA_VCF
    ch_concat_svaba_input = SVABA.out.sv.join(BCFTOOLS_INDEX.out.tbi)
        .map { meta, vcf, tbi ->
            [ meta + [ id: "${meta.subject_id}" ], vcf, tbi ]
        }
        .groupTuple()
        .map { meta, vcfs, tbis ->
            [ meta, vcfs.toSorted(), tbis.toSorted() ]
        }

    CONCAT_SVABA_VCF(
        ch_concat_svaba_input
    )

    ch_versions = ch_versions.mix(CONCAT_MANTA_VCF.out.versions.first())

    // MANTA
    MANTA_SOMATIC(
        ch_caller_input,
        ch_genome,
        ch_genome_fai,
        ch_genome_dict,
    )

    ch_versions = ch_versions.mix(MANTA_SOMATIC.out.versions.first())

    // MODULE: CONCAT_MANTA_VCF
    ch_merge_vcf_input = MANTA_SOMATIC.out.somatic_sv_vcf.join(MANTA_SOMATIC.out.somatic_sv_vcf_tbi)
        .map { meta, vcf, tbi ->
            [ meta + [ id: "${meta.subject_id}.somatic_sv" ], vcf, tbi ]
        }
        .groupTuple()
        .map { meta, vcfs, tbis ->
            [ meta, vcfs.toSorted(), tbis.toSorted() ]
        }

    CONCAT_MANTA_VCF(
        ch_merge_vcf_input
    )

    ch_versions = ch_versions.mix(CONCAT_MANTA_VCF.out.versions.first())

    emit:
    vcf_filtered = GRIPSS_SOMATIC.out.vcf_filtered
    vcf_somatic = GRIPSS_SOMATIC.out.vcf_somatic
    versions = ch_versions // channel: [ versions.yml ]
}
