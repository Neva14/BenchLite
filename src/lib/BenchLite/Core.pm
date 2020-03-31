#  Copyright 2020 Robert Bakaric and Neva Skrabar
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#
#

package BenchLite::Core;


=head1 NAME

Bench::BenchLite - Simple Benchmark module for batch based CLI applications

=head1 SYNOPSIS

    use Bench::BenchLite;
    my $object = Bench::BenchLite->new();
    print $object->as_string;

=head1 DESCRIPTION

Benchmarking is the practice of comparing processes and performance metrics to
industry standard best practice solutions. Parameters typically considered
within a measurment process are:

  a) quality of the resulting output,
  b) execution time
  c) memory usage
  d) disc usage

"BenchLite" is a simple module for building fast and simple  benchmarking applications
under Unix environment.

=head1 LICENSE

The softare is released under the General Public License. See L<perlartistic>.

=head1 AUTHOR

Robert Bakaric and Neva Skrabar

=head1 SEE ALSO

L<perlpod>, L<perlpodspec>


=head2 Methods



=over 12

=item C<new>

Constructor: returns a new Bench::BenchLite object.


=begin html
 <br>Figure 1.<IMG SRC="figure.jpg"><br>
=end html


=item C<as_string>

Returns a stringified representation of
the object. This is mainly for debugging
purposes.

=back

=cut



#---------------------------------------------------------#
#                     Libraries
#---------------------------------------------------------#

use strict;
use warnings;
use Time::HiRes;
use File::Basename qw( fileparse );
use File::Path qw( make_path );
use File::Spec;
use Proc::ProcessTable;
use IO::CaptureOutput qw/capture_exec/;
use BenchLite::Stats::Summary;
use BenchLite::Stats::Matrix;
use BenchLite::UI;
use BenchLite::Plot::Utility;
use Statistics::R;
use Data::Dumper;


#---------------------------------------------------------#
#                      CONSTRUCTOR
#---------------------------------------------------------#

sub new {
    my ($class) = @_;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    my $time = $sec."s".$min."m".$hour."h".$mday."d".($mon+1)."m".($year%100)."y";

    #-----------------------Sandbox-----------------------#
    my $self->{_name_}     =  "Bench";
    $self->{_date_}        =  $time;
    $self->{_suffix_}      =  ".bench";
    $self->{_output_}      =  "./Bench";
    $self->{_def_name_}    =  $time;
    $self->{_log_}         =  "Bench.log";

    #------------------------Stats------------------------#
    $self->{_stats_}       =  0;
    $self->{_stats_table_} =  ();

    #---------------------Def. values---------------------#
    $self->{_bootstrap_}   =  0;
    $self->{_delta_}       =  1;

    #---------------------Shell Script--------------------#
    $self->{_script_}      =  {};

    bless $self, $class;
    return $self;
}


#---------------------------------------------------------#
#                  Public methods
#---------------------------------------------------------#

sub benchmark {

  my ($self, $arg) = @_;

  $self->_makepath("$self->{_output_}/$self->{_def_name_}");

  my $script = BenchLite::UI->new();

  $script->parse_script($arg);
  $self->{_script_} = $script->get_script();

  #print Dumper($self->{_script_});

  my ($ptout, $out) = ("","");

  print "Benchmarking  ...\n" ;

  foreach my $c (sort {$a <=> $b} keys %{$self->{_script_}->{"cmd"}}) {

    my $pid = $$;
    $ptout  = "$self->{_script_}->{cmd}->{$c}->{exe}";

    for (my $b = 1; $b <= $self->{_bootstrap_}; $b++){

      $out = "[Iter: $b] $ptout  ... ";
      print "$out\r";

        my $pid = fork;

        if (not defined $pid) {
           warn 'Could not fork';
           next;
        }

        if ($pid) {
          sleep $self->{_delta_};
          $self->_measure_memory( $pid+2, $c, $b);

        } else {

          my $ppd = $$ + 2;
          # Time
          $self->_measure_runtime( $ppd, $c, $b );
          # Disc
          $self->_measure_disc( $ppd, $c, $b );

          exit 0;
        }
      }

      wait();

      print "$out Done! \n";
      sleep $self->{_delta_};
  }

  $self->_load_stats();


  return 1;
}





sub plot {

  my ($self, $select, $data) = @_;

  if (not defined $data) {
    $data = $self->{_stats_table_};
  }

  if (not defined $select) {
    $data = $self->{_script_};
  }

  my $R = Statistics::R->new(shared => 1);
  my $plot = BenchLite::Plot::Utility->new();
  $plot->{_R_} = $R;

  my $summary = $plot->plot($select,$data);
  $R->stop();

  return $summary;
}


#---------------------------------------------------------#
#                       Getters
#---------------------------------------------------------#


sub get_summary_stats {

  my ($self) = @_;

  return $self->{_stats_table_};
}

sub get_plot_logic {

  my ($self) = @_;
  return $self->{_script_};

}


sub get_raw_stats {

  my ($self, $flag) = @_;

  if ($self->{_stats_}  == 0){
    die "$!\nYou need to run: \$obj->compute_stats() first!";
  }

  if ($flag eq "as_string") {

    return Dumper($self->{_stats_table_});

  }elsif ($flag eq "as_table"){

    return $self->_make_table();

  }elsif ($flag eq "as_object"){

    return $self->{_stats_table_};

  }else{
    die "$!\n$flag not recognized!\n";
  }

}



#---------------------------------------------------------#
#                  Private methods
#---------------------------------------------------------#



sub _compute_raw_stats {

  my ($self) = @_;

  $self->{_summary_table_} = "";
}



sub _make_table {

  my ($self) = @_;

  ## hash to tsv
}


sub _compute_summary_stats {

  my ($self, $tab, $waht, $file) = @_;

  my ($boot, $mes, $x) = (0,0,0);
  my $matrix  = BenchLite::Stats::Matrix->new();


  open (IN, "<", $file) || die "$!";

  while(<IN>){

    chomp;
    if (/^#(.*)/){
      my @head = split("\t", $1);

      foreach my $col (@head){
        if ($col eq "Bootstrap"){
          $boot = $x;
        }elsif( $col eq "Cmd" || $col =~ /Mem\(/){
          $mes = $x;
          last;
        }
        $x++;
      }

    }else{
      my @data  = split("\t", $_);

      my @log    = @data[0..($boot-1)];
      my @tmpdat = @data[($boot+2)..($mes-1)];
      my @cmd    = @data[$mes..(@data-1)];

      $matrix->recompute_stats_matrix(\@tmpdat);

      if ($data[$boot]  == $self->{_bootstrap_}){

        my @avgdat = ();
        foreach my $sts (@{$matrix->get_stats_matrix()}){
          push(@avgdat, $sts->get_mean(), $sts->get_sd());
        }

        push (@{$tab->{$waht}{"logic"}}, \@log );
        push (@cmd, $data[$boot], $data[$boot+1] );
        push (@{$tab->{$waht}{"data"}},  \@avgdat );
        push (@{$tab->{$waht}{"cmd"}},   \@cmd );
      }
    }
  }

  close IN;

}


sub _load_stats {

  my ($self) = @_;

  my %table = ();

  $self->_compute_summary_stats(\%table, "runtime", "$self->{_output_}/$self->{_def_name_}/$self->{_name_}.rtime.log");

  $self->_compute_summary_stats(\%table, "memory", "$self->{_output_}/$self->{_def_name_}/$self->{_name_}.mem.log");

  $self->_compute_summary_stats(\%table, "disc", "$self->{_output_}/$self->{_def_name_}/$self->{_name_}.disc.log");

  $self->{_stats_table_} = \%table;

}


sub _measure_memory {

  my ($self, @arg) = @_;

  my $stats = BenchLite::Stats::Summary->new();
  my ($mem,$try) = (1, 3);
  my @mem = ();

  while ($try > 0) {
    sleep $self->{_delta_};
    $mem = $self->_memory_usage($arg[0]);
    if ($mem > 0){
      push(@mem,$mem);
      $try=3;
    }else{
      push(@mem,1);
      $try--;
    }
  }

  open(OM, ">>", "$self->{_output_}/$self->{_def_name_}/$self->{_name_}.mem.log") || die "$!";

  print OM "#"
    .join("\t",@{$self->{_script_}->{"head"}->{"tags"}->{0}})
    ."\tBootstrap"
    ."\tPID"
    ."\tMemAvg(MB)"
    ."\tMemSD(MB)"
    ."\tMemMax(MB)"
    ."\tMem(MB)_[$self->{_delta_} sec]"
    ."\tCmd"
    ."\n" if $arg[1] == 0 && $arg[2] == 1 ;

  $stats->compute_sd(@mem);
  $stats->compute_max(@mem);

  print OM ""
    .join("\t",@{$self->{_script_}->{"cmd"}->{$arg[1]}->{"tags"}})
    ."\t" . $arg[2]
    ."\t" . $arg[0]
    ."\t" . $stats->get_mean(@mem)
    ."\t" . $stats->get_sd(@mem)
    ."\t" . $stats->get_max(@mem)
    ."\t" . join(",",@mem)
    ."\t" . $self->{_script_}->{"cmd"}->{$arg[1]}->{"exe"}
    ."\n";

  close OM;

}

sub _measure_runtime{

  my ($self, @arg) = @_;

  my $start_time = [Time::HiRes::gettimeofday()];
  system("$self->{_script_}->{cmd}->{$arg[1]}->{exe} 2> $self->{_output_}/$self->{_def_name_}/$self->{_log_}");
  my ($user, $system, $child_user, $child_system) = times;
  my $clock =  Time::HiRes::tv_interval($start_time);



  open(OT, ">>", "$self->{_output_}/$self->{_def_name_}/$self->{_name_}.rtime.log") || die "$!";

  print OT "#"
    .join("\t",@{$self->{_script_}->{"head"}->{"tags"}->{0}})
    ."\tBootstrap"
    ."\tPID"
    ."\tUserTime"
    ."\tSysTime"
    ."\tTotTime"
    ."\tCmd"
    ."\n" if $arg[1] == 0 && $arg[2] == 1 ;

  print OT ""
    .join("\t",@{$self->{_script_}->{"cmd"}->{$arg[1]}->{"tags"}})
    ."\t" . $arg[2]
    ."\t" . $arg[0]
    ."\t" . $child_user
    ."\t" . $child_system
    ."\t" . $clock
    ."\t" . $self->{_script_}->{"cmd"}->{$arg[1]}->{"exe"}
    ."\n";

  close OT;

}


sub _measure_disc {

  my ($self,@arg) = @_;

  my @flags = @{$self->{_script_}->{"cmd"}->{$arg[1]}->{"flags"}};
  my @cmd   = split(" ",$self->{_script_}->{"cmd"}->{$arg[1]}->{"exe"});
  my @flag_res = ();

  for (my $q=0; $q<@cmd; $q++){
    for (my $f = 0; $f < @flags; $f++) {
      if ($cmd[$q] eq $flags[$f]){
        my $d = qx(du -b $cmd[$q+1]);
        $d=~/^(.*?)\s+/;
        $flag_res[$f] = $1;
      }
    }
  }


  open(OD, ">>", "$self->{_output_}/$self->{_def_name_}/$self->{_name_}.disc.log") || die "$!";

  print OD "#"
    .join("\t",@{$self->{_script_}->{"head"}->{"tags"}->{0}})
    ."\tBootstrap"
    ."\tPID"
    ."\tDiscUsageFlags:"
    .join("\t",@{$self->{_script_}->{"head"}->{"flags"}->{0}})
    ."\tCmd"
    ."\n" if $arg[1] == 0 && $arg[2] == 1 ;

  print OD ""
    .join("\t",@{$self->{_script_}->{"cmd"}->{$arg[1]}->{"tags"}})
    ."\t" . $arg[2]
    ."\t" . $arg[0]
    ."\t" . join("\t",@flag_res)
    ."\t" . $self->{_script_}->{"cmd"}->{$arg[1]}->{"exe"}
    ."\n";

  close OD;

}

sub _makepath {

  my ($self,$directory) = @_;

  if ( !-d $directory ) {
      make_path $directory or die "Failed to create path: $directory";
  }
}



sub _memory_usage() {

    my ($self,$pp) = @_;

    my $t = new Proc::ProcessTable;
    foreach my $got (@{$t->table}) {
        next unless $got->pid eq $pp;
        return (sprintf ("%.2f", $got->size));
    }

}


1;
