#!/usr/bin/env Rscript
library(ggplot2)
library(RColorBrewer)
suppressMessages(library(dplyr))
library(stringr)
theme_set(theme_bw())

# Setup convenience globals
isotypes = c('Ala', 'Arg', 'Asn', 'Asp', 'Cys', 'Gln', 'Glu', 'Gly', 'His', 'Ile', 'iMet', 'Leu', 'Lys', 'Met', 'Phe', 'Pro', 'Ser', 'Thr', 'Trp', 'Tyr', 'Val')

paired_positions = c('X1.72'='1:72', 'X2.71'='2:71', 'X3.70'='3:70', 'X4.69'='4:69', 'X5.68'='5:68', 'X6.67'='6:67', 'X7.66'='7:66', 'X8.14'='8:14', 'X9.23'='9:23', 'X10.25'='10:25', 'X10.45'='10:45', 'X11.24'='11:24', 'X12.23'='12:23', 'X13.22'='13:22', 'X15.48'='15:48','X18.55'='18:55', 'X19.56'='19:56', 'X22.46'='22:46', 'X26.44'='26:44', 'X27.43'='27:43', 'X28.42'='28:42', 'X29.41'='29:41', 'X30.40'='30:40', 'X31.39'='31:39', 'X49.65'='49:65', 'X50.64'='50:64', 'X51.63'='51:63', 'X52.62'='52:62', 'X53.61'='53:61', 'X54.58'='54:58')
paired_identities = c('GC', 'AU', 'UA', 'CG', 'GU', 'UG', 'PairDeletion', 'PurinePyrimidine', 'PyrimidinePurine', 'StrongPair', 'WeakPair', 'Wobble', 'Paired', 'Bulge', 'Mismatched')
paired_colors = c('GC'='gray20', 'AU'='gray20', 'UA'='gray20', 'CG'='gray20', 'GU'='gray20', 'UG'='gray20', 'PairDeletion'='gray20', 'PurinePyrimidine'='gray40', 'PyrimidinePurine'='gray40', 'StrongPair'='gray40', 'WeakPair'='gray40', 'Wobble'='gray40', 'Paired'='gray40', 'Bulge'='gray40', 'Mismatched'='gray40')

single_positions = c('X8'='8', 'X9'='9', 'X14'='14', 'X15'='15', 'X16'='16', 'X17'='17', 'X18'='18', 'X19'='19', 'X20'='20', 'X20a'='20a', 'X21'='21', 'X26'='26', 'X32'='32', 'X33'='33', 'X34'='34', 'X35'='35', 'X36'='36', 'X37'='37', 'X38'='38', 'X44'='44', 'X45'='45', 'X46'='46', 'X47'='47', 'X48'='48', 'X54'='54', 'X55'='55', 'X56'='56', 'X57'='57', 'X58'='58', 'X59'='59', 'X60'='60', 'X73'='73')
single_identities = c('A', 'C', 'G', 'U', 'Deletion', 'Purine', 'Pyrimidine', 'Weak', 'Strong', 'Amino', 'Keto', 'B', 'D', 'H', 'V')
single_colors = c('A'='gray20', 'C'='gray20', 'G'='gray20', 'U'='gray20', 'Deletion'='gray20', 'Purine'='gray40', 'Pyrimidine'='gray40', 'Weak'='gray40', 'Strong'='gray40', 'Amino'='gray40', 'Keto'='gray40', 'B'='gray40', 'D'='gray40', 'H'='gray40', 'V'='gray40')

# Get user input
args = commandArgs(trailingOnly=TRUE)
seq = args[1]
input_species_clade = args[2]
input_isotypes = args[3]
input_isotypes = unlist(str_split(input_isotypes, ','))

# Read in data
isotype_specific = read.table('single-trna-heatmap/isotype-specific.tsv', sep='\t', header=TRUE, stringsAsFactors=FALSE)
clade_isotype_specific = read.table('single-trna-heatmap/clade-isotype-specific.tsv', sep='\t', header=TRUE, stringsAsFactors=FALSE)
identities = rbind(cbind(isotype_specific, clade='Eukarya'), cbind(clade_isotype_specific))
genome_table = read.delim('single-trna-heatmap/genome_table+.txt', header=FALSE, sep='\t', stringsAsFactors=FALSE)
if (input_species_clade %in% genome_table$V5) {
  input_clade = input_species_clade
} else {
  input_clade = genome_table[genome_table$V2 == input_species_clade, ]$V5
}

# write fasta file
fasta_file = paste0('temp-', input_species_clade, '-', input_isotypes[1], '.fa')
fasta_handle = file(fasta_file) 
writeLines(c(paste0(">", fasta_file), seq), fasta_file)
close(fasta_handle)

# Align seq
model = '/projects/lowelab/users/blin/tRNAscan/models/current/TRNAinf-euk.cm'
output = system(paste('cmalign -g --notrunc', model, fasta_file), intern=TRUE)
seq = tail(unlist(str_split(output[4], '\\s+')), 1)
ss = tail(unlist(str_split(output[6], '\\s+')), 1)

# Get seq numbering
output = system(paste0('printf "', seq, '\\n', ss, '" | python single-trna-heatmap/position_interface.py'), intern=TRUE)
df = data.frame(t(matrix(unlist(str_split(output, '\\s')), nrow=2)), input_isotypes[1], "Input", stringsAsFactors=FALSE)
codes = c("A"="A", "C"="C", "G"="G", "U"="U", "-"="Deletion", "."="Deletion", "A:A"="Mismatched", "G:G"="Mismatched", "C:C"="Mismatched", "U:U"="Mismatched", "A:G"="Mismatched", "A:C"="Mismatched", "C:A"="Mismatched", "C:U"="Mismatched", "G:A"="Mismatched", "U:C"="Mismatched", "A:-"="Bulge", "U:-"="Bulge", "C:-"="Bulge", "G:-"="Bulge", "-:A"="Bulge", "-:G"="Bulge", "-:C"="Bulge", "-:U"="Bulge", "A:U"="AU", "U:A"="UA", "C:G"="CG", "G:C"="GC", "G:U"="GU", "U:G"="UG", "-:-"="PairDeletion")
df$identity = codes[df$X2]

# Filter out varm and insertions
df = df %>% filter(!str_detect(X1, "i") & !str_detect(X1, 'V'))

# Wrangle to fit main data frame
df$X1 = gsub("^", "X", gsub(':', '.', df$X1))
df = df[, c(3, 1, 5, 4)]
colnames(df) = c("isotype", "positions", "identity", "clade")
identities = rbind(identities, df)

# Wrange main data frame for plotting
matches_input = function(isotype, positions, identity) {
  codes = list(A='A', C='C', G='G', U='U', Deletion='Deletion', Purine=c('A', 'G', 'Purine'), Pyrimidine=c('C', 'U', 'Pyrimidine'), Weak=c('A', 'U', 'Weak'), Strong=c('G', 'C', 'Strong'), Amino=c('A', 'C', 'Amino'), Keto=c('G', 'U', 'Keto'), B=c('C', 'G', 'U', 'B', 'Strong', 'Pyrimidine', 'Keto'), D=c('A', 'G', 'U', 'D', 'Purine', 'Weak', 'Keto'), H=c('A', 'C', 'U', 'H', 'Amino', 'Weak', 'Pyrimidine'), V=c('A', 'C', 'G', 'V', 'Amino', 'Purine', 'Strong'), GC='GC', AU='AU', UA='UA', CG='CG', GU='GU', UG='UG', PairDeletion='PairDeletion', PurinePyrimidine=c('AU', 'GC', 'PurinePyrimidine'), PyrimidinePurine=c('UA', 'CG', 'PyrimidinePurine'), StrongPair=c('GC', 'CG', 'StrongPair'), WeakPair=c('AU', 'UA', 'WeakPair'), Wobble=c('GU', 'UG', 'Wobble'), Paired=c('AU', 'UA', 'CG', 'GC', 'GU', 'UG', 'Paired', 'PurinePyrimidine', 'PyrimidinePurine', 'StrongPair', 'WeakPair', 'Wobble'), Bulge=c('Bulge'), Mismatched=c('AA', 'GG', 'CC', 'UU', 'AG', 'AC', 'CA', 'CU', 'GA', 'UC', 'Mismatched', 'Paired', 'PurinePyrimidine', 'PyrimidinePurine', 'StrongPair', 'WeakPair', 'Wobble'))
  input_identity = identities[identities$positions == positions & identities$clade == "Input", ]$identity
  if (length(input_identity) != 1) print(paste("Too many codes", isotype, positions, identity))
  return(input_identity %in% codes[[as.character(identity)]])
}
identities = identities %>% 
  filter(isotype %in% input_isotypes & clade %in% c("Eukarya", "Input", input_clade)) %>% 
  mutate(category=ifelse(clade != "Input", paste0(isotype, ' - ', clade), "Your Sequence")) %>%
  rowwise() %>% mutate(Match=matches_input(isotype, positions, identity))


# Single plot
plot = identities %>% filter(positions %in% names(single_positions)) %>%
  mutate(positions=factor(positions, names(single_positions))) %>%
  mutate(identity=factor(identity, single_identities)) %>%
  ggplot() + geom_tile(aes(x=positions, y=category, fill=identity, color=identity), width=0.9, height=0.9, size=0.5) + 
    geom_point(aes(x=positions, y=category, shape=Match)) +
    scale_shape_manual(values=c(4, 1), labels=c("Conflict", "Match")) +
    theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5), legend.position='bottom') + 
    scale_x_discrete(labels=single_positions) +
    scale_color_manual(values=single_colors) +
    scale_fill_manual(values=c(brewer.pal(5, "Set1"), brewer.pal(12, "Set3"))) +
    guides(fill=guide_legend(title=NULL, nrow=2), color=guide_legend(title=NULL, nrow=2), shape=guide_legend(title=NULL)) + 
    xlab('Position') + ylab('Dataset')
ggsave(plot, file='single-plot.png', width=8, height=1.6+0.44*length(input_isotypes))

# Paired plot
plot = identities %>% 
  filter(positions %in% names(paired_positions)) %>%
  mutate(positions=factor(positions, names(paired_positions))) %>%
  mutate(identity=factor(identity, paired_identities)) %>%
  ggplot() + geom_tile(aes(x=positions, y=category, fill=identity, color=identity), width=0.9, height=0.9, size=0.5) + 
    geom_point(aes(x=positions, y=category, shape=Match)) +
    scale_shape_manual(values=c(4, 1), labels=c("Conflict", "Match")) +
    theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5), legend.position='bottom') + 
    scale_x_discrete(labels=paired_positions) +
    scale_color_manual(values=paired_colors) +
    scale_fill_manual(values=c(brewer.pal(5, "Set1"), brewer.pal(12, "Set3"))) +
    guides(fill=guide_legend(title=NULL, nrow=2), color=guide_legend(title=NULL, nrow=2), shape=guide_legend(title=NULL)) + 
    xlab('Position') + ylab('Dataset')
ggsave(plot, file='paired-plot.png', width=8, height=1.75+0.46*length(input_isotypes))