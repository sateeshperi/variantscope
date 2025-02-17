# gridss
/home/ubuntu/tools/gridss-2.13.2/scripts/gridss —jvmheap 50g —otherjvmheap 50g —jar /home/ubuntu/tools/gridss-2.13.2/gridss-2.13.2-gridss-jar-with-dependencies.jar —reference /media/ssd/data/reference/Homo_sapiens_assembly38.fa /media/ssd/data/bams/SAMPLENAME_normal.bam /media/ssd/data/bams/SAMPLENAME_tumor.bam -o SAMPLENAME.vcf —threads 45

# gripss
java -jar ~/tools/gripss_v2.4.jar -sample SAMPLENAME_tumor -reference SAMPLENAME_normal -vcf SAMPLENAME.vcf -ref_genome_version 38 -ref_genome /media/ssd/data/reference/Homo_sapiens_assembly38.fa -output_dir ./

# amber
java -jar ~/tools/amber_v4.0.jar -reference SAMPLENAME_normal -reference_bam /media/ssd/data/bams/SAMPLENAME_normal.bam -tumor SAMPLENAME_tumor -tumor_bam /media/ssd/data/bams/SAMPLENAME_tumor.bam -output_dir ./ -threads 45 -loci /media/ssd/data/reference/hmf-public/v5_34/ref/38/copy_number/AmberGermlineSites.38.tsv.gz -ref_genome_version 38

# cobalt
java -jar ~/tools/cobalt_v1.16.jar -reference SAMPLENAME_normal -reference_bam /media/ssd/data/bams/SAMPLENAME_normal.bam -tumor SAMPLENAME_tumor -tumor_bam /media/ssd/data/bams/SAMPLENAME_tumor.bam -output_dir ./ -threads 45 -gc_profile /media/ssd/data/reference/hmf-public/v5_34/ref/38/copy_number/GC_profile.1000bp.38.cnp

# purple
java -jar ~/tools/purple_v4.0.jar -reference SAMPLENAME_normal -tumor SAMPLENAME_tumor -amber /media/ssd/data/amber_output/SAMPLENAME -cobalt /media/ssd/data/cobalt_output/SAMPLENAME -gc_profile /media/ssd/data/reference/hmf-public/v5_34/ref/38/copy_number/GC_profile.1000bp.38.cnp -ref_genome /media/ssd/data/reference/Homo_sapiens_assembly38.fa -ref_genome_version 38 -ensembl_data_dir /media/ssd/data/reference/hmf-public/v5_34/ref/38/common/ensembl_data/ -somatic_sv_vcf /media/ssd/data/gridss_output/SAMPLENAME/SAMPLENAME_tumor.gripss.filtered.vcf.gz -circos /home/ubuntu/miniconda3/bin/circos -output_dir ./

# linx
java -jar ~/tools/linx_v1.25.jar -sample SAMPLENAME_tumor -ref_genome_version 38 -sv_vcf /media/ssd/data/purple_output/SAMPLENAME/SAMPLENAME_tumor.purple.sv.vcf.gz -output_dir ./ -purple_dir /media/ssd/data/purple_output/SAMPLENAME -ensembl_data_dir /media/ssd/data/reference/hmf-public/v5_34/ref/38/common/ensembl_data/ -known_fusion_file /media/ssd/data/reference/hmf-public/v5_34/ref/38/sv/known_fusion_data.38.csv -driver_gene_panel /media/ssd/data/reference/hmf-public/v5_34/ref/38/common/DriverGenePanel.38.tsv -log_debug -write_all

java -cp ~/tools/linx_v1.25.jar com.hartwig.hmftools.linx.visualiser.SvVisualiser -sample SAMPLENAME_tumor -ref_genome_version 38 -ensembl_data_dir /media/ssd/data/reference/hmf-public/v5_34/ref/38/common/ensembl_data/ -plot_out ./ -data_out ./ -vis_file_dir ./ -circos /home/ubuntu/miniconda3/bin/circos

