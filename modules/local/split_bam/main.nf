process SPLIT_BAM {
    tag "${meta.id}"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    input:
    tuple val(meta), path(t_bam), path(t_bai), path(n_bam), path(n_bai)
    val num_chunks
    val chunk_overlap

    output:
    tuple val(meta), path("*.tumor.bam")        , emit: t_bam
    tuple val(meta), path("*.tumor.bam.bai")    , emit: t_bai
    tuple val(meta), path("*.normal.bam")       , emit: n_bam
    tuple val(meta), path("*.normal.bam.bai")   , emit: n_bai
    path  "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "$meta.id"
    """
    n_proc=\$(nproc 2>/dev/null || < /proc/cpuinfo grep '^process' -c)

    echo -e "Getting list of contigs and their sizes from the tumor bam...\\n"

    contigs=(\$(samtools idxstats $t_bam | cut -f1 | grep -v '*'))
    sizes=(\$(samtools idxstats $t_bam | cut -f2 | grep -v '*'))
    num_contigs=\${#contigs[@]}

    echo -e "Found contigs: \${contigs[@]}, with sizes: \${sizes[@]}\\n"

    total_size=0
    for size in "\${sizes[@]}"; do
        total_size=\$((total_size + size))
    done

    echo -e "Total genomic size: \$total_size bp\\n"

    echo -e "Get a list of normal bam contigs..."
    n_bam_contigs=(\$(samtools idxstats $n_bam | cut -f1 | grep -v '*'))
    echo -e "Normal bam contigs: \${n_bam_contigs[@]}\\n"

    num_possible_chunks=$num_chunks
    if (($num_chunks > num_contigs)); then
        num_possible_chunks=\$num_contigs
        echo -e "Number of chunks is greater than the number of contigs. Setting number of chunks to the number of contigs: \$num_possible_chunks\\n"
    fi

    chunk_size=\$((total_size / \$num_possible_chunks))
    echo -e "Chunk size: \$chunk_size bp"

    overlap_size=\$((chunk_size * $chunk_overlap / 100))
    step_size=\$((chunk_size - overlap_size))

    echo -e "Overlap size: \$overlap_size bp"
    echo -e "Step size: \$step_size bp\\n"

    start=0
    last_chunk_contigs=()
    for ((i = 1; i <= \$num_possible_chunks; i++)); do
        echo -e "Processing chunk \$i..."

        end=\$((start + chunk_size))
        if ((i == \$num_possible_chunks)); then
            end=\$total_size  # Ensure last chunk includes all remaining bases
        fi
        echo -e "Chunk \$i: Start = \$start, End = \$end"

        chunk_start=\$start
        chunk_end=\$end
        chunk_contigs=()
        chunk_position=0

        for ((j = 0; j < num_contigs; j++)); do
            contig_size=\${sizes[j]}
            contig_end=\$((chunk_position + contig_size))

            if ((chunk_end > chunk_position && chunk_start < contig_end)); then
                chunk_contigs+=("\${contigs[j]}")
                echo -e "Adding contig \${contigs[j]} to chunk \$i"
            fi

            chunk_position=\$contig_end
        done

        echo -e "Contigs in chunk \$i: \${chunk_contigs[@]}"

        if [ "\$(printf "%s " "\${chunk_contigs[@]}")" == "\$(printf "%s " "\${last_chunk_contigs[@]}")" ]; then
            echo -e "Chunk \$i has the same contigs as the previous chunk. Skipping...\\n"
            continue
        fi

        echo -e "Running samtools view on tumor bam for chunk \$i..."

        samtools view -b $args --threads \$((n_proc-1)) $t_bam "\${chunk_contigs[@]}" \
            > "${prefix}.chunk\${i}.tumor.bam"

        echo -e "Make sure normal bam has the chunk contigs..."
        intersection_contigs=(\$(comm -12 <(printf "%s\\n" "\${n_bam_contigs[@]}" | sort) <(printf "%s\\n" "\${chunk_contigs[@]}" | sort)))
        echo -e "Intersection contigs: \${intersection_contigs[@]}"

        echo -e "Running samtools view on normal bam for chunk \$i..."

        samtools view -b $args --threads \$((n_proc-1)) $n_bam "\${intersection_contigs[@]}" \
            > "${prefix}.chunk\${i}.normal.bam"

        echo -e "Chunk \$i BAM files created: ${prefix}.chunk\${i}.tumor.bam, ${prefix}.chunk\${i}.normal.bam\\n"

        start=\$((start + step_size))
        last_chunk_contigs=("\${chunk_contigs[@]}")
    done

    echo -e "Chunking complete!"

    for bam in *.chunk*bam; do
        echo -e "Indexing \$bam..."
        samtools \\
            index \\
            -@ \$((n_proc-1)) \\
            $args2 \\
            "\$bam"
    done

    echo -e "Indexing complete!"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "$meta.id"
    """
    touch ${prefix}.chr1.split.normal.bam
    touch ${prefix}.chr1.split.normal.bam.bai
    touch ${prefix}.chr1.split.tumor.bam
    touch ${prefix}.chr1.split.tumor.bam.bai

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
