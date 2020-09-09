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
//secondString="_2"

//Defines the script usage/purpose
if (params.help) {
  log.info"""
  BIGSI ret_conv_class pipeline.
  Performs retrieval of reads/fastq files published on the ENA since date specified (January 1st, 2017 by default).
  Date can be changed by modifying the variable 'end' under process 'retReadTxt'.
  Usage: nextflow ret_reads.nf

  """
  .stripIndent()

  exit 0
}

//Retrieves a list of reads/samples based upon the week in which they were made public
process retReadTxt {
  executor 'lsf'
  maxForks 40
  errorStrategy {task.attempt < 3 ? 'retry' : 'ignore'}

  output:
  file "*_Reads_Week*.txt" into allReads optional true

  script:
  """
#!/hps/covid19_nobackup2/research/ena/blaise/bigsi/miniconda3/bin/python
#Import libraries
from urllib.request import urlretrieve
from dateutil import rrule
from datetime import datetime,date, timedelta

#Define start & end dates for read retrieval
now = date(${params.enddate})
end = date(${params.startdate})

#Create counter for each week
counter = 1

#Loop through the weeks
for dt in rrule.rrule(rrule.WEEKLY, dtstart=end, until=now):
    #Define one week
    oneWeek = dt+timedelta(days=6)

    #Use API to download reads on weekly basis
    arch_reads_weekly = "https://www.ebi.ac.uk/ena/data/warehouse/search?query=%22tax_tree(2157)%20AND%20first_public%3E=" + dt.date().strftime("%Y-%m-%d") + "%20AND%20first_public%3C=" + oneWeek.date().strftime("%Y-%m-%d") + "%22&limit=0&length=0&offset=1&display=report&result=read_run&fields=sample_accession,run_accession,fastq_ftp,fastq_md5&download=txt"
    vir_reads_weekly = "https://www.ebi.ac.uk/ena/data/warehouse/search?query=%22tax_tree(10239)%20AND%20first_created%3E=" + dt.date().strftime("%Y-%m-%d") + "%20AND%20first_public%3C=" + oneWeek.date().strftime("%Y-%m-%d") + "%22&limit=0&length=0&offset=1&display=report&result=read_run&fields=sample_accession,run_accession,fastq_ftp,fastq_md5&download=txt"
    #bac_reads_weekly = "https://www.ebi.ac.uk/ena/data/warehouse/search?query=%22tax_tree(2)%20AND%20first_created%3E=" + dt.date().strftime("%Y-%m-%d") + "%20AND%20first_public%3C=" + oneWeek.date().strftime("%Y-%m-%d") + "%22&limit=358768&length=358768&offset=1&display=report&result=read_run&fields=sample_accession,run_accession,fastq_ftp,fastq_md5&download=txt"
    bac_reads_weekly = "https://www.ebi.ac.uk/ena/data/warehouse/search?query=%22tax_tree(2)%20AND%20first_created%3E=" + dt.date().strftime("%Y-%m-%d") + "%20AND%20first_public%3C=" + oneWeek.date().strftime("%Y-%m-%d") + "%22&limit=0&length=0&offset=1&display=report&result=read_run&fields=sample_accession,run_accession,fastq_ftp,fastq_md5&download=txt"

    #Define week string
    weekNo = dt.date().isocalendar()[1]
    weekNoStr = str(weekNo)

    #Define output files
    vir_reads_file_weekly = "Vir_Reads_Week" + weekNoStr + "_" + dt.date().strftime("%Y") + ".txt"
    arch_reads_file_weekly = "Arc_Reads_Week" + weekNoStr + "_" + dt.date().strftime("%Y") + ".txt"
    bac_reads_file_weekly = "Bac_Reads_Week" + weekNoStr + "_" + dt.date().strftime("%Y") + ".txt"

    #Download read files
    urlretrieve(vir_reads_weekly, vir_reads_file_weekly)
    urlretrieve(arch_reads_weekly, arch_reads_file_weekly)
    urlretrieve(bac_reads_weekly, bac_reads_file_weekly)
  """
}

//Cut out the sample accession no. for enaGroupGet (first column)
//Remove lines without any sample accession
process cutReads {
  executor 'lsf'
  publishDir params.cutTxtWeekDir, mode: 'copy', overwrite: false
  maxForks 40
  errorStrategy {task.attempt < 3 ? 'retry' : 'ignore'}

  input:
  each readWeek from allReads

  output:
  file "cut${cutReads}Final" into cutRead optional true

  //Substring & cut out the first column
  script:
  cutReads = readWeek.toString()
  cutReads = cutReads.substring(cutReads.lastIndexOf("/")+1,cutReads.size())
  """
  cut -f3 ${readWeek} > cut${cutReads}
  sed "s/ftp.sra.ebi.ac.uk\\/vol1\\//https:\\/\\/fire.sdo.ebi.ac.uk\\/fire\\/public\\/era\\//g" cut${cutReads} > cut${cutReads}1
  sed '1d' cut${cutReads}1 > cut${cutReads}2
  sed "s/;/\\n/g" cut${cutReads}2 > cut${cutReads}3
  sed -i '/^\$/d' cut${cutReads}3
  sed "s/;/\\n\\n/g" cut${cutReads}3 > cut${cutReads}Final
  """
}

process downReads {
  executor 'lsf'
  cache 'deep'
  maxForks 10
  errorStrategy 'retry'
  maxRetries 1
  publishDir params.readStore, mode: 'move', overwrite: false

  input:
  file fireFile from cutRead

  output:
  file ("*_1.fastq*.gz") into (fastq_split1, fastq_split1_15, fastq_split1_krak2) mode flatten optional true
  file ("*_2.fastq*.gz") into (fastq_split2, fastq_split2_15, fastq_split2_krak2) mode flatten optional true
  file ("*{1,2,3,4,5,6,7,8,9,0}{1,2,3,4,5,6,7,8,9,0}.fastq.*") into (fastq_31, fastq_15, fastq_kraken2) mode flatten optional true

  script:
  week = fireFile.toString()
  week = week.substring(week.lastIndexOf("Week"), week.length())
  week = week.replace(".txtFinal","")
  """
  sleep 5
  if grep -q https:// $fireFile; then
    /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/parallel --gnu /gpfs/nobackup/ena_flash_test/blaise/bigsi/miniconda3/bin/wget --tries=0 --retry-connrefused --continue --timeout=30 --random-wait < $fireFile
  fi
  """
}


