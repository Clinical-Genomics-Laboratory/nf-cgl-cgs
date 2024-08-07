process DRAGEN_DEMULTIPLEX {
    tag "${prefix.id}"
    label 'dragen'

    container "${ workflow.profile == 'dragenaws' ?
        'ghcr.io/dhslab/docker-dragen:el8.4.3.6' :
        'dockerreg01.accounts.ad.wustl.edu/cgl/dragen:v4.3.6' }"

    input:
    path(samplesheet)
    path(rundir)

    output:
    path("demux_fastq/fastq_list.csv"), emit: fastq_list
    path("demux_fastq/*")             , emit: demux_files
    path("versions.yml")              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix     = task.ext.prefix
    def first_tile = params.bcl_first_tile ? "--first-tile-only true" : ""
    """
    mkdir -p demux_fastq

    # Perform demultiplexing of samples
    /opt/dragen/4.3.6/bin/dragen \\
        --bcl-conversion-only true \\
        --bcl-only-matched-reads true \\
        --strict-mode true \\
        ${first_tile} \\
        --sample-sheet ${samplesheet} \\
        --bcl-input-directory ${rundir} \\
        --output-directory demux_fastq

    # Copy RunParameters.xml to demux_fastq/Reports
    find ${rundir} \\
        -type f \\
        -name "RunParameters.xml" \\
        -exec cp '{}' demux_fastq/Reports/ \\;

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dragen: \$(/opt/dragen/4.3.6/bin/dragen --version | head -n 1 | cut -d ' ' -f 3)
    END_VERSIONS
    """

    stub:
    """
    mkdir -p demux_fastq

    cp ${projectDir}/assets/stub/demux_fastq/Reports/fastq_list.csv demux_fastq/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dragen: \$(cat ${projectDir}/assets/stub/versions/dragen_version.txt)
    END_VERSIONS
    """
}
