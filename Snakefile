import pandas as pd

# 1. Carrega os metadados
configfile: "config.yaml"

# 2. Lê a tabela samples.tsv
samples_df = pd.read_csv("samples.tsv", sep="\t").set_index("sample_id", drop=False)
SAMPLES = samples_df["sample_id"].tolist()

# 3. Função para montar o link do ENA automaticamente usando wget
def get_ena_url(wildcards):
    srr = samples_df.loc[wildcards.sample, "srr"]
    pasta = "00" + srr[-1]
    return f"ftp://ftp.sra.ebi.ac.uk/vol1/fastq/{srr[:6]}/{pasta}/{srr}/{srr}.fastq.gz"

# 4. Regra Mestra: O que queremos gerar no final desta etapa?
rule all:
    input:
        expand("data/raw/{sample}.fastq.gz", sample=SAMPLES),
        expand("results/fastqc/{sample}_fastqc.html", sample=SAMPLES),
        expand("results/salmon/{sample}/quant.sf", sample=SAMPLES),
        "results/Relatorio_GSE128198.html",
        "results/multiqc_report.html"

# 5. Regra de Download: Executa o wget
rule download_fastq:
    output:
        "data/raw/{sample}.fastq.gz"
    params:
        url = get_ena_url
    shell:
        """
        wget -c {params.url} -O {output}
        """

# 6. Regra de Controle de Qualidade: FastQC
rule fastqc:
    input:
        "data/raw/{sample}.fastq.gz"
    output:
        html = "results/fastqc/{sample}_fastqc.html",
        zip = "results/fastqc/{sample}_fastqc.zip"
    conda:
        "envs/fastqc.yaml"
    shell:
        """
        fastqc {input} -o results/fastqc/
        """

# 7. Regra para criar o índice do Salmon (Blindada contra o WSL)
rule salmon_index:
    input:
        "reference/transcriptome.fa.gz"
    output:
        directory("reference/salmon_index")
    conda:
        "envs/salmon.yaml"
    shell:
        """
        # 1. Cria o índice no diretório temporário nativo do Linux (sem bugs de I/O)
        salmon index -t {input} -i /tmp/salmon_index -p 2
        
        # 2. Copia a pasta finalizada para o seu projeto no Windows
        cp -r /tmp/salmon_index {output}
        
        # 3. Limpa o lixo
        rm -rf /tmp/salmon_index
        """

# 8. Regra para quantificar as amostras com Salmon
rule salmon_quant:
    input:
        r1 = "data/cleaned/{sample}.fastq.gz",
        index = "reference/salmon_index"
    output:
        "results/salmon/{sample}/quant.sf"
    conda:
        "envs/salmon.yaml"
    shell:
        """
        salmon quant -i {input.index} -l A -r {input.r1} -p 2 -o results/salmon/{wildcards.sample}/
        """

# 9. Regra para gerar o Relatório HTML em R
rule relatorio_rmd:
    input:
        quants = expand("results/salmon/{sample}/quant.sf", sample=SAMPLES),
        tx2gene = "reference/tx2gene.csv",
        metadata = "samples.tsv"
    output:
        "results/Relatorio_GSE128198.html"
    conda:
        "envs/rnaseq.yaml"
    script:
        "scripts/relatorio.Rmd"

# 10. Regra de Limpeza: Fastp
rule fastp:
    input:
        "data/raw/{sample}.fastq.gz"
    output:
        cleaned = "data/cleaned/{sample}.fastq.gz",
        html = "results/fastp/{sample}_fastp.html",
        json = "results/fastp/{sample}_fastp.json"
    conda:
        "envs/fastp.yaml"
    shell:
        "fastp -i {input} -o {output.cleaned} -h {output.html} -j {output.json}"

# 11. Regra de Agregação de Qualidade: MultiQC
rule multiqc:
    input:
        fastqc = expand("results/fastqc/{sample}_fastqc.zip", sample=SAMPLES),
        fastp = expand("results/fastp/{sample}_fastp.json", sample=SAMPLES)
    output:
        "results/multiqc_report.html"
    conda:
        "envs/multiqc.yaml"
    shell:
        "multiqc results/ -o results/"
