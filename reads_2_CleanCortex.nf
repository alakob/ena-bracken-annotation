//Script parameters - mostly directories where the data will be stored
params.help = false

params.ctx31 = "./cobsCtx31Mers/"
params.clean = "./cobsCtxClean/"
params.readStore = "./readStore/"
//params.readStore = "./storedRead/"

// paired-reads channels
//For cortex31
fastq_split = Channel.fromFilePairs('./readStore/*_{1,2}.fastq.gz', flat: true).set { reads }
//fastq_split = Channel.fromFilePairs('./storedRead/*_{1,2}.fastq.gz', flat: true).set { reads }


//Single reads
//For cortex31
fastq_31 = Channel.fromPath( './readStore/*{1,2,3,4,5,6,7,8,9,0}{1,2,3,4,5,6,7,8,9,0}.fastq.*' )
//fastq_31 = Channel.fromPath( './storedRead/*{1,2,3,4,5,6,7,8,9,0}{1,2,3,4,5,6,7,8,9,0}.fastq.*' )

//Single reads cortex creation (k-mer size 31)
process cortexCreation31 {
  publishDir params.ctx31, mode: 'copy', overwrite: false
  executor 'lsf'
  maxForks 30
  errorStrategy 'retry'
  maxRetries 8
  memory { 15.GB * task.attempt }

  input:
  file fastq from fastq_31

  output:
  file "$fastqStr$ctxStr" into singleCtx optional true

  script:
  fastqStr=fastq.toString()
  fastqStr=fastqStr.substring(0, fastqStr.indexOf("."))
  ctxStr=".ctx"
  ctxMem=10*task.attempt
  gStr="G"
  """
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/mccortex31 build --threads 10 -f -m $ctxMem$gStr -k 31 --fq-cutoff 5 -s $fastqStr -1 $fastq $fastqStr$ctxStr
  """
}

//Paired reads cortex creation (k-mer size 31)
process cortexCreation31Paired {
  publishDir params.ctx31, mode: 'copy', overwrite: false
  executor 'lsf'
  maxForks 30
  errorStrategy 'retry'
  maxRetries 8
  memory { 15.GB * task.attempt }

  input:
  set val(id), file(read1), file(read2) from reads

  output:
  file "$fastqStr$ctxStr" into pairCtx optional true

  script:
  fastqStr=read1.toString()
  fastqStr=fastqStr.substring(0, fastqStr.indexOf("."))
  fastqStr=fastqStr.replace("_1","")
  ctxStr=".ctx"
  ctxMem=10*task.attempt
  gStr="G"
  """
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/mccortex31 build --threads 10 -f -m $ctxMem$gStr -k 31 --fq-cutoff 5 -s $fastqStr -2 $read1:$read2 $fastqStr$ctxStr
  """
}


//Single read cortex cleaning (takes the size 31 k-mer cortex files)
process cortexClean {
  publishDir params.clean, mode: 'copy', overwrite: false
  executor 'lsf'
  maxForks 30
  errorStrategy 'retry'
  maxRetries 8
  memory { 15.GB * task.attempt }

  input:
  file ctxSingle from singleCtx
  // val weekStr from weekFile4

  output:
  file "$fastqStr$cleanStr" into cleanCtx, buildBloom

  script:
  fastqStr=ctxSingle.toString()
  fastqStr=fastqStr.replace(".ctx","")
  cleanStr=".clean.ctx"
  ctxMem=10*task.attempt
  gStr="G"
  """
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/mccortex31 clean --threads 10 -o $fastqStr$cleanStr -f --fallback 5 -m $ctxMem$gStr $ctxSingle
  """
}

//Paired reads cortex cleaning (take the size 31 k-mer cortex files)
process cortexCleanPaired {
  publishDir params.clean, mode: 'copy', overwrite: false
  executor 'lsf'
  maxForks 30
  errorStrategy 'retry'
  maxRetries 8
  memory { 15.GB * task.attempt }

  input:
  file ctxPair from pairCtx
  // val weekStr from weekFile5

  output:
  file "$fastqStr$cleanStr" into cleanCtx1, buildBloom1

  script:
  fastqStr=ctxPair.toString()
  fastqStr=fastqStr.replace(".ctx","")
  cleanStr=".clean.ctx"
  ctxMem=10*task.attempt
  gStr="G"
  """
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/mccortex31 clean --threads 10 -o $fastqStr$cleanStr -f --fallback 5 -m $ctxMem$gStr $ctxPair
  """
}

