include {AMBER} from '../../../modules/local/amber/main'
include {COBALT} from '../../../modules/local/cobalt/main'
include {PURPLE} from '../../../modules/local/purple/main'


params.amber_germline_sites = params.amber_germline_sites ?: "${projectDir}/assets/references/AmberGermlineSites.38.tsv.gz"
params.gc_profile = params.gc_profile ?: "${projectDir}/assets/references/GC_profile.1000bp.38.cnp"
params.genome = params.genome ?: "${projectDir}/assets/references/hg38.fa"
params.genome_fai = params.genome_fai ?: "${projectDir}/assets/references/hg38.fa.fai"
params.genome_dict = params.genome_dict ?: "${projectDir}/assets/references/hg38.dict"
params.ensembl_path = params.ensembl_path ?: "${projectDir}/assets/references/ensembl"

    
genome                  = Channel.of(file(params.genome))
genome_fai              = Channel.of(file(params.genome_fai))
genome_dict             = Channel.of(file(params.genome_dict))
amber_germline_sites                  = Channel.of(file(params.amber_germline_sites))
gc_profile                            = Channel.of(file(params.gc_profile))
ensembl_path                          = Channel.of(file(params.ensembl_path))

workflow CNV_CALLING {

    take:
    ch_bam
    gripps_filtered_vcf

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
   /*
    ch_purple_input = ch_bam
        .combine(AMBER.out.amber_dir,by:[0])
        .combine(COBALT.out.cobalt_dir,by:[0])
        .combine(gripps_filtered_vcf,by:[0])

    PURPLE(ch_purple_input,
        Channel.of('hg38'),
        genome,
        genome_fai,
        genome_dict,
        gc_profile,
        ensembl_path
    )

    */
   

    versions = ch_versions                     // channel: [ versions.yml ]


}
