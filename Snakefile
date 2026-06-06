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
        expand("results/fastqc/{sample}_fastqc.html", sample=SAMPLES)

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
        "envs/fastqc.yaml" # Aqui a mágica da reprodutibilidade acontece!
    shell:
        """
        fastqc {input} -o results/fastqc/
        """
