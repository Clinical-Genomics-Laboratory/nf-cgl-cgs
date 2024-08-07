/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CREATE_DEMULTIPLEX_SAMPLESHEET   } from '../../modules/local/create_demultiplex_samplesheet'
include { DRAGEN_DEMULTIPLEX               } from '../../modules/local/dragen_demultiplex'
include { INPUT_CHECK as VERIFY_FASTQ_LIST } from '../../subworkflows/local/input_check'


/*
========================================================================================
    SUBWORKFLOW TO CHECK INPUTS
========================================================================================
*/

workflow DEMULTIPLEX {

    take:
    ch_samplesheet      // channel: [ path(file) ]
    ch_illumina_run_dir // channel: [ path(dir) ]

    main:
    ch_versions = Channel.empty()

    //
    // MODULE: Create demultiplex samplesheet
    //
    CREATE_DEMULTIPLEX_SAMPLESHEET (
        ch_samplesheet,
        ch_illumina_run_dir
    )
    ch_versions = ch_versions.mix(CREATE_DEMULTIPLEX_SAMPLESHEET.out.versions)

    //
    // MODULE: Demultiplex samples
    //
    DRAGEN_DEMULTIPLEX (
        CREATE_DEMULTIPLEX_SAMPLESHEET.out.samplesheet,
        ch_illumina_run_dir
    )
    ch_versions = ch_versions.mix(DRAGEN_DEMULTIPLEX.out.versions)

    //
    // SUBWORKFLOW: Verify fastq_list.csv
    //
    VERIFY_FASTQ_LIST (
        [],
        DEMULTIPLEX.out.fastq_list
    )
    ch_versions = ch_versions.mix(VERIFY_FASTQ_LIST.out.versions)

    emit:
    samples  = VERIFY_FASTQ_LIST.out.samples
    versions = ch_versions

}
