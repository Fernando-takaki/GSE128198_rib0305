# GSE128198_rib0305

# Pipeline Reprodutível de RNA-seq: Análise do Locus 11q13.5 em Células T
**Disciplina:** Laboratório de Bioinformática (RIB0305)
**Dataset:** [GSE128198](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE128198)

## Contexto Biológico
Este projeto investiga o papel de um *enhancer* genético associado a doenças autoimunes, localizado no locus 11q13.5. O estudo avalia como a deleção deste enhancer afeta o perfil transcricional de células **Treg** (T reguladoras, que suprimem a inflamação) e **Tconv** (T convencionais). 
O design experimental é um **fatorial 2x2**, totalizando 12 amostras de *Mus musculus*:
* **Tipos Celulares:** Treg vs. Tconv
* **Genótipo:** Selvagem (WT) vs. Nocaute do Enhancer (Enh-KO)

## Arquitetura do Pipeline
Para garantir total reprodutibilidade, escalabilidade e controle de ambiente, todo o fluxo de trabalho foi orquestrado utilizando **Snakemake** e **Conda**. 

As etapas automatizadas incluem:
1. **Aquisição de Dados:** Download direto via FTP do European Nucleotide Archive (ENA) utilizando a ferramenta `wget`, otimizando a estabilidade da rede.
2. **Controle de Qualidade (QC) e Limpeza:** * Extração de métricas brutas via `FastQC`.
   * Trimming de adaptadores e filtragem de qualidade com `fastp`.
   * Agregação de todos os relatórios em um painel único utilizando `MultiQC`.
3. **Quantificação Baseada em Transcriptoma:** * Indexação e pseudoalinhamento das amostras utilizando `Salmon` contra o transcriptoma de referência do Ensembl.
4. **Análise de Expressão Diferencial e Relatório:**
   * Importação de dados no R via `tximport`.
   * Modelagem de distribuição binomial negativa com `DESeq2` utilizando a fórmula `~ cell_type * enhancer_ko`.
   * Geração automática de relatório HTML via `R Markdown`.

## Como Reproduzir a Análise
Pré-requisitos: Ter o gerenciador de pacotes `Conda` e o `Snakemake` instalados no ambiente Linux.

```bash
# 1. Clone este repositório
git clone [https://github.com/SEU-USUARIO/GSE128198_RNAseq.git](https://github.com/SEU-USUARIO/GSE128198_RNAseq.git)
cd GSE128198_RNAseq

# 2. Execute o pipeline completo orquestrado pelo Snakemake
# A flag --use-conda instrui a montagem automática de todos os ambientes virtuais
snakemake --use-conda -j 4
```
