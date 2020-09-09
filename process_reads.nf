//Script parameters - mostly directories where the data will be stored
params.help = false
params.cutTxtWeekDir = "readTextFiles"
params.enddate = "2021,1,1"
params.startdate = "2020,1,1"
params.readDir = "./readFiles"
params.ctx31 = "./ctx31Mers/"
params.ctx15 = "./ctx15Mers/"
params.krak = "./krakWeeks/"
params.clean = "./ctxClean/"
params.brack = "./brackWeeks/"
params.brackPaired = "./brackWeeksPaired/"
params.unitigs = "./unitigWeeks/"
params.sour = "./sourWeeks"
params.blooms = "./bloomWeeks/"
params.yaml = "/hps/covid19_nobackup2/research/ena/blaise/bigsi/cfg/berkdbConfigs/berkdb"
params.readStore = "./readStore/"

//Read pairs channel(s)

//For cortex31
fastq_split = Channel.fromFilePairs('./readStore/*_{1,2}.fastq.gz', flat: true).set { reads }

//For cortex 15
fastq_split_15 = Channel.fromFilePairs('./readStore/*_{1,2}.fastq.gz', flat: true).set { reads1 }

//For classification (Kraken & Bracken)
fastq_split_krak2 = Channel.fromFilePairs('./readStore/*_{1,2}.fastq.gz', flat: true).set { reads2 }

//Single reads

//For cortex31
fastq_31 = Channel.fromPath( './readStore/*{1,2,3,4,5,6,7,8,9,0}{1,2,3,4,5,6,7,8,9,0}.fastq.*' )

//For cortex15
fastq_15 = Channel.fromPath( './readStore/*{1,2,3,4,5,6,7,8,9,0}{1,2,3,4,5,6,7,8,9,0}.fastq.*' )

//For classification (Kraken & Bracken)
fastq_kraken2 = Channel.fromPath( './readStore/*{1,2,3,4,5,6,7,8,9,0}{1,2,3,4,5,6,7,8,9,0}.fastq.*' )


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
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/mccortex31 build -f -m $ctxMem$gStr -k 31 --fq-cutoff 5 -s $fastqStr -1 $fastq $fastqStr$ctxStr
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
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/mccortex31 build -f -m $ctxMem$gStr -k 31 --fq-cutoff 5 -s $fastqStr -2 $read1:$read2 $fastqStr$ctxStr
  """
}

//Paired reads cortex creation (k-mer size 15)
process cortexCreation15Paired {
  publishDir params.ctx15, mode: 'move', overwrite: false
  executor 'lsf'
  maxForks 30
  errorStrategy 'retry'
  maxRetries 8
  memory { 15.GB * task.attempt }

  input:
  set val(id), file(read1), file(read2) from reads1

  output:
  file "$fastqStr$ctxStr" optional true

  script:
  fastqStr=read1.toString()
  fastqStr=fastqStr.substring(0, fastqStr.indexOf("."))
  fastqStr=fastqStr.replace("_1","")
  ctxStr=".15.ctx"
  ctxMem=10*task.attempt
  gStr="G"
  """
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/mccortex31 build -f -m $ctxMem$gStr -k 15 --fq-cutoff 5 -s $fastqStr -2 $read1:$read2 $fastqStr$ctxStr
  """
}

//Single reads cortex creation (k-mer size 15)
process cortexCreation15 {
  publishDir params.ctx15, mode: 'move', overwrite: false
  executor 'lsf'
  maxForks 30
  errorStrategy 'retry'
  maxRetries 8
  memory { 15.GB * task.attempt }

  input:
  file fastq from fastq_15
  // val weekStr from weekFile3

  output:
  file "$fastqStr$ctxStr" optional true

  script:
  fastqStr=fastq.toString()
  fastqStr=fastqStr.substring(0, fastqStr.indexOf("."))
  pairedFile=fastq.toString()
  pairedFile=pairedFile.replace("_1","_2")
  pairedOut=fastqStr.replace("_1","")
  ctxStr=".15.ctx"
  ctxMem=10*task.attempt
  gStr="G"
  """
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/mccortex31 build -f -m $ctxMem$gStr -k 15 --fq-cutoff 5 -s $fastqStr -1 $fastq $fastqStr$ctxStr
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
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/mccortex31 clean -o $fastqStr$cleanStr -f --fallback 5 -m $ctxMem$gStr $ctxSingle
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
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/mccortex31 clean -o $fastqStr$cleanStr -f --fallback 5 -m $ctxMem$gStr $ctxPair
  """
}

//Kraken2 classification of single reads
process krak2 {
  publishDir params.krak, mode: 'copy', overwrite: false
  executor 'lsf'
  maxForks 15
  errorStrategy 'retry'
  maxRetries 3
  memory { 37.GB * task.attempt }

  input:
  file fastq1 from fastq_kraken2
  // val weekStr from weekFile6

  output:
  file "$fastqStr$krak2Str" optional true
  file "$fastqStr$krakRep" into singleKrakRep optional true

  script:
  fastqStr=fastq1.toString()
  fastqStr=fastqStr.substring(0, fastqStr.indexOf("."))
  krakRep=".kreport2"
  krak2Str=".kraken2"
  """
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/kraken2 --db /hps/covid19_nobackup2/research/ena/blaise/bigsi/cfg/kraken2-microbial-fatfree --threads 10 --report $fastqStr$krakRep $fastq1 > $fastqStr$krak2Str
  """
}

//Kraken2 classification of paired reads
process krak2Paired {
  publishDir params.krak, mode: 'copy', overwrite: false
  executor 'lsf'
  maxForks 15
  errorStrategy 'retry'
  maxRetries 3
  memory { 37.GB * task.attempt }

  input:
  set val(id), file(read1), file(read2) from reads2

  output:
  file "$fastqStr$krak2Str" optional true
  file "$fastqStr$krakRep" into pairedKrakRep optional true

  script:
  fastqStr=read1.toString()
  fastqStr=fastqStr.substring(0, fastqStr.indexOf("."))
  fastqStr=fastqStr.replace("_1","")
  krakRep=".kreport2"
  krak2Str=".kraken2"
  """
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/kraken2 --db /hps/covid19_nobackup2/research/ena/blaise/bigsi/cfg/kraken2-microbial-fatfree --threads 10 --report $fastqStr$krakRep --paired $read1 $read2 > $fastqStr$krak2Str
  """
}

//Single read bracken (takes Kraken2 output)
process brackenSingle {
  publishDir params.brack, mode: 'move', overwrite: false
  executor 'lsf'
  maxForks 15
  errorStrategy 'ignore'
  memory '10 GB'

  input:
  file krakIn from singleKrakRep
  // val weekStr from weekFile8

  output:
  file "$fastqStr$brackStr" optional true

  script:
  fastqStr=krakIn.toString()
  fastqStr=fastqStr.replace(".kreport2","")
  brackStr=".bracken"

  """
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/python /hps/covid19_nobackup/research/ena/blaise/miniconda3/bin/est_abundance.py -i $krakIn -k /hps/covid19_nobackup2/research/ena/blaise/bigsi/cfg/kraken2-microbial-fatfree/database2500mers.kmer_distrib -o $fastqStr$brackStr -l 'S' -t 10
  """

}

//Paired reads bracken (takes Kraken2 output)
process brackenPaired {
  publishDir params.brack, mode: 'move', overwrite: false
  executor 'lsf'
  maxForks 15
  errorStrategy 'ignore'
  memory '10 GB'

  input:
  file krakIn from pairedKrakRep

  output:
  file "$fastqStr$brackStr" optional true

  script:
  fastqStr=krakIn.toString()
  fastqStr=fastqStr.replace(".kreport2","")
  brackStr=".bracken"

  """
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/python /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/est_abundance.py -i $krakIn -k /hps/covid19_nobackup2/research/ena/blaise/bigsi/cfg/kraken2-microbial-fatfree/database2500mers.kmer_distrib -o $fastqStr$brackStr -l 'S' -t 10
  """
}

//Creates unitig files from cleaned cortex files (k-mer size 31) for single reads
process unitigCreation {
  publishDir params.unitigs, mode: 'copy', overwrite: false
  executor 'lsf'
  maxForks 30
  errorStrategy 'retry'
  maxRetries 8
  memory { 15.GB * task.attempt }

  input:
  file singCtx from cleanCtx

  output:
  file "$singleFastqStr$unitigStr" into uniSingle optional true

  script:
  singleFastqStr=singCtx.toString()
  singleFastqStr=singleFastqStr.replace(".clean.ctx","")
  unitigStr=".unitigs.txt"
  ctxMem=10*task.attempt
  gStr="G"
  """
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/mccortex31 unitigs -o $singleFastqStr$unitigStr -m $ctxMem$gStr $singCtx
  """
  }

//Creates unitig files from cleaned cortex files (k-mer size 31) for paired reads
process unitigCreationPaired {
  publishDir params.unitigs, mode: 'copy', overwrite: false
  executor 'lsf'
  maxForks 30
  errorStrategy 'retry'
  maxRetries 8
  memory { 15.GB * task.attempt }

  input:
  file pairedCtx from cleanCtx1

  output:
  file "$pairedFastqStr$unitigStr" into uniPair optional true

  script:
  pairedFastqStr=pairedCtx.toString()
  pairedFastqStr=pairedFastqStr.replace(".clean.ctx","")
  unitigStr=".unitigs.txt"
  ctxMem=10*task.attempt
  gStr="G"
  """
  /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/mccortex31 unitigs -o $pairedFastqStr$unitigStr -m $ctxMem$gStr $pairedCtx
  """
  }

//Takes the unitig files created from the cleaned cortex files (k-mer size 31) and creates sig files via sourmash for single reads
process sourMash {
  publishDir params.sour, mode: 'move', overwrite: false
  executor 'lsf'
  maxForks 30
  errorStrategy 'retry'
  maxRetries 8
  memory { 10.GB * task.attempt }

  input:
  file sourIn from uniSingle

  output:
  file "$fastqStr$sigStr"

  script:
  fastqStr=sourIn.toString()
  fastqStr=fastqStr.replace(".unitigs.txt","")
  sigStr=".sig"
  """
  if [[ -s $sourIn ]]; then
      /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/sourmash compute $sourIn -o $fastqStr$sigStr
  else
     touch $fastqStr$sigStr;
  fi
  """
}

//Takes the unitig files created from the cleaned cortex files (k-mer size 31) and creates sig files via sourmash for paired reads
process sourMashPaired {
  publishDir params.sour, mode: 'move', overwrite: false
  executor 'lsf'
  maxForks 30
  errorStrategy 'retry'
  maxRetries 8
  memory { 10.GB * task.attempt }

  input:
  file sourIn from uniPair

  output:
  file "$fastqStr$pairedSigStr"

  script:
  fastqStr=sourIn.toString()
  fastqStr=fastqStr.replace(".unitigs.txt","")
  pairedSigStr=".sig"
  """
  if [[ -s $sourIn ]]; then
      /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/sourmash compute $sourIn -o $fastqStr$pairedSigStr;
  else
     touch $fastqStr$pairedSigStr;
  fi
  """
}

//Create bloom files from cleaned cortex (k-mer size 31) files for single reads -- rest maxRetries to 8
//process bloomCreationBin {
//  publishDir params.blooms, mode: 'move', overwrite: false
//  executor 'lsf'
//  maxForks 30
//  errorStrategy 'retry'
//  maxRetries 8
//  memory { 15.GB * task.attempt }
//
//  input:
//  file bloomBuild from buildBloom
//
//  output:
//  file "*/$fastqStr$bloomStr"
//
//  script:
//  fastqStr=bloomBuild.toString()
//  fastqStr=fastqStr.replace(".clean.ctx","")
//  bloomStr=".bloom"
//  """
//  KOUNT="\$(/gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/mccortex31 view $bloomBuild | grep number | grep kmer | cut -f 2 -d ":")"
//  function buildBloomClean {
//      singularity exec /hps/covid19_nobackup2/research/ena/blaise/bigsi/bigsi.simg bigsi bloom --config $params.yaml\$1.yaml $bloomBuild \$bin/$fastqStr$bloomStr
//  }
//  KOUNT1=`echo \$KOUNT | sed 's/,//g'`
//  KOUNT2=\${#KOUNT1}
// if [ \$KOUNT2 -lt 6 ]; then
//      bin="binLtt5"
//      buildBloomClean "\$bin"
//  elif [ \$KOUNT2 -gt 5 ] && [ \$KOUNT2 -lt 7 ]; then
//      bin="binGtt5Ltt6"
//      buildBloomClean "\$bin"
//  elif [ \$KOUNT2 -gt 6 ] && [ \$KOUNT2 -lt 8 ]; then
//      bin="binGtt6Ltt7"
//      buildBloomClean "\$bin"
//  elif [ \$KOUNT2 -gt 7 ] && [ \$KOUNT2 -lt 9 ]; then
//      bin="binGtt7Ltt8"
//      buildBloomClean "\$bin"
//  elif [ \$KOUNT2 -gt 8 ] && [ \$KOUNT2 -lt 10 ]; then
//      bin="binGtt8Ltt9"
//      buildBloomClean "\$bin"
//  else
//      bin="binGtt9Ltt10"
//      buildBloomClean "\$bin"
//  fi
//  """
//}

//Creates bloom files for cleaned cortex (km-er sie 31) files for paired reads
//process bloomCreationBinPaired {
//  publishDir params.blooms, mode: 'move', overwrite: false
//  executor 'lsf'
//  maxForks 30
//  errorStrategy 'retry'
//  maxRetries 8
//  memory { 15.GB * task.attempt }
//
//  input:
// file bloomBuild1 from buildBloom1
//  // val weekStr from weekFile15
//
//  output:
//  file "*/$fastqStr$bloomStr"
//
//  script:
//  fastqStr=bloomBuild1.toString()
//  fastqStr=fastqStr.replace(".clean.ctx","")
//  bloomStr=".bloom"
//  """
//  KOUNT="\$(/gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/mccortex31 view $bloomBuild1 | grep number | grep kmer | cut -f 2 -d ":")"
//  function buildBloomClean {
//      singularity exec /hps/covid19_nobackup2/research/ena/blaise/bigsi/bigsi.simg bigsi bloom --config $params.yaml\$1.yaml $bloomBuild1 \$bin/$fastqStr$bloomStr
//  }
//  KOUNT1=`echo \$KOUNT | sed 's/,//g'`
//  KOUNT2=\${#KOUNT1}
// if [ \$KOUNT2 -lt 6 ]; then
//      bin="binLtt5"
//      buildBloomClean "\$bin"
//  elif [ \$KOUNT2 -gt 5 ] && [ \$KOUNT2 -lt 7 ]; then
//      bin="binGtt5Ltt6"
//      buildBloomClean "\$bin"
//  elif [ \$KOUNT2 -gt 6 ] && [ \$KOUNT2 -lt 8 ]; then
//      bin="binGtt6Ltt7"
//      buildBloomClean "\$bin"
//  elif [ \$KOUNT2 -gt 7 ] && [ \$KOUNT2 -lt 9 ]; then
//      bin="binGtt7Ltt8"
//      buildBloomClean "\$bin"
//  elif [ \$KOUNT2 -gt 8 ] && [ \$KOUNT2 -lt 10 ]; then
//      bin="binGtt8Ltt9"
//      buildBloomClean "\$bin"
//  else
//      bin="binGtt9Ltt10"
//      buildBloomClean "\$bin"
//  fi
// """
//}

