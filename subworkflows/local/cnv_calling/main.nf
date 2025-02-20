include {AMBER} from '../../../modules/local/amber/main'
include {COBALT} from '../../../modules/local/cobalt/main'


params.amber_germline_sites = params.amber_germline_sites ?: "${projectDir}/assets/references/AmberGermlineSites.38.tsv.gz"
params.gc_profile = params.gc_profile ?: "${projectDir}/assets/references/GC_profile.1000bp.38.cnp"

amber_germline_sites                  = Channel.of(file(params.amber_germline_sites))
gc_profile                            = Channel.of(file(params.gc_profile))

workflow CNV_CALLING {

    take:
    ch_bam

    main:

    ch_versions = Channel.empty()

    AMBER(ch_bam
        .combine(Channel.of('hg38'))
        .combine(amber_germline_sites)
    )

    ch_versions = ch_versions.mix(AMBER.out.versions.first())

    COBALT(ch_bam
        .combine(gc_profile)
    )

    ch_versions = ch_versions.mix(COBALT.out.versions.first())

    versions = ch_versions                     // channel: [ versions.yml ]


}
