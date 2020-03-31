#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use lib "../lib";

#---------------------------------------------------------#
#                PiedPiper construction
#---------------------------------------------------------#

# construct object manager
use BenchLite::Core;
my $bench = BenchLite::Core->new();

#---------------------------------------------------------#
#                        CLI
#---------------------------------------------------------#

my ($help,$script,$out,$boot,$deltaT,$example);

GetOptions ("i=s" => \$script,
            "h" => \$help,
            "o=s" => \$out,
            "b=i" => \$boot,
            "d=i" => \$deltaT,
            "e"  => \$example
            );

if($help  || !$script ){
  print "Usage:\n\n";
  print "\t-i\tInput script [*.bench]\n";
  print "\t-o\tOutput table [tsv]\n";
  print "\t-b\tNumber of times to repeat a given measurment\n";
  print "\t-d\tTime interval for memory snaps [in sec]\n";
  print "\t-e\tPrint out bench template\n";
  print "\n\nExecution example\n";
  print "bench -o MyResults.tsv -b 3 -d 2 -i my.bench\n";
  exit(0);
}

if ($example){
  print_example();
  exit(0);
}

#---------------------------------------------------------#
#                     pre-check
#---------------------------------------------------------#

# set the number of benchmark repetitions
$boot = 1 unless $boot;

# define output if not set it prints to stdout
my $ofh ;
if ($out){
  open ($ofh, ">", $out) || die "$!";
}

# bootstrap mode set to 0 means only a single cmd execution will be preformed
$bench->{_bootstrap_} = $boot;

# define the output path
$bench->{_output_} = "./Benchmarks";
$bench->{_log_} = "Bench.log";
$bench->{_delta_} = 1;


#---------------------------------------------------------#
#                         main
#---------------------------------------------------------#

# execute *.bench script
$bench->benchmark($script);

# get benchmark results
my $table  = $bench->get_summary_stats();
my $logic  = $bench->get_plot_logic();

# plot results (currently plots all formats)
my $plot_data = $bench->plot($logic, $table);

# print out data used for plotting
foreach my $line (@{$plot_data}){
  my $skip = ($line->[0] eq 'TableName') ? ("\n") : ("");
  if ($out){
    print $ofh "$skip". join("\t", @{$line}) . "\n";
  }else{
    print "$skip". join("\t", @{$line}) . "\n";
  }
}


#---------------------------------------------------------#
#                      post-check
#---------------------------------------------------------#

if ($out){
  close $ofh;
}


#---------------------------------------------------------#
#                        functions
#---------------------------------------------------------#



sub print_example {

print << "E";

# Plot definition:
#Function:-------Tag,------Tag-:-PlotTitle----------------#

\%TagClasses:    Tool,     NGS
#---------------------------------------------------------#
\%PlotRuntime:  T1/T2,      -  : First
\%PlotRuntime:     T1,   HiSeq : Second
\%PlotDisc:        T1,      -  : Tool1
\%PlotDisc:        T2, NovaSeq : Tool2
\%PlotMemory:   T1/T2,      -  : Memory



\%FlagClasses: In, Out
#---------------------------------------------------------#
#
# Aplications:

# app:1
#---------------------------------------------------------#

\%Tags:   T1, HiSeq
\%Flags:   -i,>

perl tool1.pl -i in -x 100  > out.1
#---------------------------------------------------------#

# app:2
#---------------------------------------------------------#

\%Tags:   T2, NovaSeq
\%Flags:   -i,-o


tool2  -x 100 -i in -o out.1
#---------------------------------------------------------#
E
}
