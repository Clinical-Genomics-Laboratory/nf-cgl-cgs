process DRAGEN_JOINT_CNV {
    tag "${cnv_files[0].toString().split('\\.')[0]}"
    label 'dragen'

    container "${ workflow.profile == 'dragenaws' ?
        'ghcr.io/dhslab/docker-dragen:el8.4.3.6' :
        'dockerreg01.accounts.ad.wustl.edu/cgl/dragen:v4.3.6' }"

    input:
    path(cnv_files)

    output:
    tuple val(task.ext.prefix), path("*cnv.vcf.gz"), emit: joint_cnv
    path("versions.yml")                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix   = task.ext.prefix
    def ref_dir  = params.refdir ? "--ref-dir ${params.refdir}" : ""
    def cnv_list = cnv_files.collect{ "--cnv-input $it" }.join(' \\\\n')
    """
    /opt/edico/bin/dragen \\
        --force \\
        ${ref_dir} \\
        ${cnv_list} \\
        --enable-cnv true \\
        --output-directory \$PWD \\
        --output-file-prefix ${prefix.id}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dragen: \$(/opt/edico/bin/dragen --version | tail -n 1 | cut -d ' ' -f 3)
    END_VERSIONS
    """

    stub:
    def dragen_version = "4.2.4"
    def prefix         = task.ext.prefix
    def ref_dir        = params.refdir ? "--ref-dir ${params.refdir}" : ""
    def cnv_list       = cnv_files.collect{ "--cnv-input $it" }.join(' \\\\n')
    """
    cat <<-END_CMDS > "${prefix.id}.txt"
    /opt/edico/bin/dragen \\
        --force \\
        ${ref_dir} \\
        ${cnv_list} \\
        --enable-cnv true \\
        --output-directory \$PWD \\
        --output-file-prefix ${prefix.id}
    END_CMDS

    cp -f ${projectDir}/assets/test_data/dragen_path/joint_genotyped_vcf/joint_genotyped.vcf.gz .
    mv joint_genotyped.vcf.gz ${prefix.id}.cnv.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dragen: ${dragen_version}
    END_VERSIONS
    """
}
