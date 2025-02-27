# SowpatiLab/variantscope

## Introduction

**SowpatiLab/variantscope** is a bioinformatics pipeline that ...

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
subject_id,sample_id,sample_type,sequence_type,filetype,filepath,indexpath
subject_a,subject_a_tumor,tumor,dna,bam,assets/test-data/subject_a_tumor.dna.bwa-mem2_2.2.1.markdups.bam,assets/test-data/subject_a_tumor.dna.bwa-mem2_2.2.1.markdups.bam.bai
subject_a,subject_a_normal,normal,dna,bam,assets/test-data/subject_a_normal.dna.bwa-mem2_2.2.1.markdups.bam,assets/test-data/subject_a_normal.dna.bwa-mem2_2.2.1.markdups.bam.bai
```

Each row represents either a tumor or normal sample for a subject, with details about the sample type, sequence type, file type, and paths to the sequence and index files.



Now, you can run the pipeline using:

```bash
nextflow run SowpatiLab/variantscope \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

## Credits

SowpatiLab/variantscope was originally written by Isha Choubey.

We thank the following people for their extensive assistance in the development of this pipeline:

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
