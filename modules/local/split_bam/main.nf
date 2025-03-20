process SPLIT_BAM {
    tag "${meta.id}"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    input:
    tuple val(meta), path(input), path(index)
    val num_chunks
    val chunk_overlap

    output:
    tuple val(meta), path("*.split.bam")        , emit: bam
    tuple val(meta), path("*.split.bam.bai")    , emit: bai
    path  "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "$meta.id"
    """
    echo "Getting list of contigs and their sizes..."
    contigs=(\$(samtools idxstats $input | cut -f1 | grep -v '*'))
    sizes=(\$(samtools idxstats $input | cut -f2 | grep -v '*'))

    total_size=0
    for size in "\${sizes[@]}"; do
        total_size=\$((total_size + size))
    done

    echo "Total genomic size: \$total_size bp"

    chunk_size=\$((total_size / $num_chunks))
    echo "Chunk size: \$chunk_size bp"

    overlap_size=\$((chunk_size * $chunk_overlap / 100))
    step_size=\$((chunk_size - overlap_size))

    echo "Overlap size: \$overlap_size bp"
    echo "Step size: \$step_size bp"

    start=0
    for ((i = 1; i <= $num_chunks; i++)); do
        echo "Processing chunk \$i..."

        end=\$((start + chunk_size))
        if ((i == $num_chunks)); then
            end=\$total_size  # Ensure last chunk includes all remaining bases
        fi
        echo "Chunk \$i: Start = \$start, End = \$end"

        # Determine which contigs belong to the current chunk based on genomic positions
        chunk_start=\$start
        chunk_end=\$end
        chunk_contigs=()
        chunk_position=0

        for ((j = 0; j < num_contigs; j++)); do
            contig_size=\${sizes[j]}
            contig_end=\$((chunk_position + contig_size))

            # Add contig to the chunk if it overlaps with the chunk's range
            if ((chunk_end > chunk_position && chunk_start < contig_end)); then
                chunk_contigs+=("\${contigs[j]}")
                echo "Adding contig \${contigs[j]} to chunk \$i"
            fi

            # Update the position for the next contig
            chunk_position=\$contig_end
        done

        echo "Contigs in chunk \$i: \${chunk_contigs[@]}"

        echo "Running samtools view for chunk \$i..."
        samtools view -b \$args --threads ${task.cpus-1} $input "\${chunk_contigs[@]}" \
            > "${prefix}.chunk\${i}.split.bam"

        echo "Chunk \$i BAM file created: ${prefix}.chunk\${i}.split.bam"

        start=\$((start + step_size))
    done

    echo "Chunking complete!"

    for bam in *.split.bam; do
        samtools \\
            index \\
            -@ ${task.cpus-1} \\
            $args2 \\
            "\$bam"
    done

    echo "Indexing complete!"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "$meta.id"
    """
    touch ${prefix}.chr1.split.bam
    touch ${prefix}.chr1.split.bam.bai

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
