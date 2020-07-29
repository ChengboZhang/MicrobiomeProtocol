    # ���������miniconda2
    wget -c https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh
    bash Miniconda2-latest-Linux-x86_64.sh
    conda -V # 4.8.3
    python --version # 2.7.15
    # �������Ƶ���������ҵ�����ѧ���
    conda config --add channels bioconda
    conda config --add channels conda-forge

    # ��ѡ�������⻷������ֹ��Ⱦ��������
    conda create -n qc2 python=2.7

	# ��װ����Ͳ鿴�汾
    conda install fastqc -y
    fastqc -v # FastQC v0.11.9
    conda install multiqc -y
    multiqc --version # multiqc, version 1.7
    conda install kneaddata -y
    kneaddata --version # 0.6.1
	conda install parallel -y
    parallel --version # 20200522


    mkdir -p db
	# �鿴���õ������������ࡢС������顢����ת¼��ͺ��������ݿ�
	kneaddata_database
	# �������������������bowite 2����
    kneaddata_database --download human_genome bowtie2 db

# ʵ�鲽��

## 1.	׼����������

	# ���ļ����½��ļ��б��棬-p�������༶Ŀ¼�����Ŀ¼��Ŀ¼�Ѵ���Ҳ������
	mkdir -p seq
	# wget���ص���������-cΪ֧�ֶϵ�������-Oָ������λ�ò�����������ÿ��˫���������������ļ�
	wget -c ftp://download.big.ac.cn/gsa/CRA002355/CRR117732/CRR117732_f1.fq.gz -O seq/C2_1.fq.gz
	wget -c ftp://download.big.ac.cn/gsa/CRA002355/CRR117732/CRR117732_r2.fq.gz -O seq/C2_2.fq.gz
	# ���forѭ��������3��������seq��������������У�$i�滻�����пɱ䲿�֣���β��\��֤��������ȷʶ��
	for i in `seq 3 5`;do
	wget -c ftp://download.big.ac.cn/gsa/CRA002355/CRR11773$i/CRR11773$i\_f1.fq.gz -O seq/C$i\_1.fq.gz
	wget -c ftp://download.big.ac.cn/gsa/CRA002355/CRR11773$i/CRR11773$i\_r2.fq.gz -O seq/C$i\_2.fq.gz
	done

## 2.	FastQC����������������

	# ��*.fq.gz����������.fq.gz��β���ļ�������ǰ���в������ݣ�-t 3ָ�����ͬʱʹ��3���߳�
	fastqc seq/*.fq.gz -t 3

## 3.	MultiQC����������������

	# -dָ������Ŀ¼��-oָ�����Ŀ¼
    multiqc -d seq/ -o ./

## 4.	������˫�����б�ǩ�Ƿ�Ψһ

	# �鿴�����Ƿ��ǩ���ظ�
	zcat seq/C2_1.fq.gz|head
	zcat seq/C2_2.fq.gz|head

	# ��ѹ�������е����Ҷ˱����зֱ���\1��\2
	gunzip seq/*.gz
    sed -i '1~4 s/$/\\1/g' seq/*_1.fq
    sed -i '1~4 s/$/\\2/g' seq/*_2.fq
	# �˶������Ƿ��ǩ���ظ�
	head seq/C2_1.fq
	head seq/C2_2.fq
	# ѹ����ʡ�ռ�
    gzip seq/*.fq

## 4.	KneadData�������ƺ�ȥ����

    kneaddata -h # ��ʾ����
	# ��λ�������ʿغ�ȥ����
    kneaddata -i seq/C2_1.fq.gz -i seq/C2_2.fq.gz \
      -o qc/ -v -t 8 --remove-intermediate-output \
      --trimmomatic ~/.conda/envs/qc2/share/trimmomatic \
      --trimmomatic-options 'ILLUMINACLIP:~/.conda/envs/qc2/share/trimmomatic/adapters/TruSeq3-PE.fa:2:40:15 SLIDINGWINDOW:4:20 MINLEN:50' \
      --bowtie2-options '--very-sensitive --dovetail' -db db/hg37dec_v0.1

	# parallel������У�����2������ͬʱ����
    parallel -j 2 --xapply \
      "kneaddata -i seq/C{1}_1.fq.gz \
      -i seq/C{1}_2.fq.gz \
      -o qc/ -v -t 8 --remove-intermediate-output \
      --trimmomatic ~/.conda/envs/qc2/share/trimmomatic \
      --trimmomatic-options 'ILLUMINACLIP:~/.conda/envs/qc2/share/trimmomatic/adapters/TruSeq3-PE.fa:2:40:15 SLIDINGWINDOW:4:20 MINLEN:50' \
      --bowtie2-options '--very-sensitive --dovetail' -db db/hg37dec_v0.1" \
      ::: `seq 3 5`

	# �����ʿػ��ܱ�
    kneaddata_read_count_table \
      --input qc \
      --output kneaddata_sum.txt
	# ��ȡraw��trim��final�ؼ����
	cut -f 1-5,12-13 kneaddata_sum.txt | sed 's/_1_kneaddata//;s/pair//g' > kneaddata_report.txt

## 5.	(��ѡ)�ʿغ����������� 

    fastqc qc/*_1_kneaddata_paired_*.fastq -t 2
    multiqc -d qc/ -o ./


# ��������

## 1. ������������޷�����

	# ����廪conda����
	site=https://mirrors.tuna.tsinghua.edu.cn/anaconda
	conda config --add channels $site/pkgs/free/ 
	conda config --add channels $site/pkgs/main/
	conda config --add channels $site/cloud/conda-forge/
	conda config --add channels $site/pkgs/r/
	conda config --add channels $site/cloud/bioconda/

## 2. ���ݿ����������޷�����

