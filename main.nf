subreads_ch = Channel.fromPath('subreads.fasta.fofn').first()
bam_ch = Channel.fromPath('subreads.bam.fofn')
hic_ch = Channel.fromPath('F1_bull_test.HiC_R*.fastq.gz')
dir = $workflow.launchDir

publish_dir = dir + "/publish"

process fc_run {
    publishDir "${publish_dir}"

    // TODO: Set something that makes sense here!
    cpus 4
    memory '8 GB'
    time '8h'

    // Load into anaconda
    conda 'pb-assembly.yml'

    input:
        file x from subreads_ch

    output:
        file("0-rawreads/") into (rawreads1, rawreads2)
        file("1-preads_ovl/") into (preads1, preads2)
        file("2-asm-falcon/") into (asm1, asm2)

    script:
        """
        sed -i "s/outs.write('/#outs.write('/" ${workflow.workDir}/conda/*/lib/python3.7/site-packages/falcon_kit/mains/ovlp_filter.py
        fc_run ${workflow.launchDir}/fc_run.cfg
        """
}

process fc_unzip {
    publishDir "${publish_dir}"

    // TODO: Set something that makes sense here!
    cpus 4
    memory '8 GB'
    time '8h'

    module 'anaconda'

    // Load into anaconda
    conda 'pb-assembly.yml'

    input:
        file x from rawreads1
        file x from preads1
        file x from asm1
        file x from bam_ch
        file x from subreads_ch

    output:
        file("3-unzip/*") into unzip
        file("4-polish/*") into polish

    script:
        """
        fc_unzip.py ${dir}/fc_unzip.cfg &> run1.std
        """
}
process fc_phase {
    publishDir "${publish_dir}"

    // TODO: Set something that makes sense here!
    cpus 4
    memory '8 GB'
    time '8h'

    module 'anaconda'

    // Load into anaconda
    conda 'pb-assembly.yml'
    
    input:
        file x from rawreads2
        file x from preads2
        file x from asm2
        file("3-unzip/") from unzip
        file("4-polish/") from polish
        file x from hic_ch
        file x from subreads_ch
    
    output:
        file("5-phase/*") into phase

    script:
        """
        fc_phase.py ${workflow.launchDir}/fc_phase.cfg &> run2.std
        """
}
