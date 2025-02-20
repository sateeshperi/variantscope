include {AMBER} from '../../../modules/local/amber/main'


params.amber_germline_sites = params.amber_germline_sites ?: "${projectDir}/assets/references/AmberGermlineSites.38.tsv.gz"


amber_germline_sites                  = Channel.of(file(params.amber_germline_sites))

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

    versions = ch_versions                     // channel: [ versions.yml ]




}