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

package BenchLite::Plot::Utility;
#---------------------------------------------------------#
#                     Libraries
#---------------------------------------------------------#

use strict;
use warnings;
use Data::Dumper;
use BenchLite::Plot::Runtime;
use BenchLite::Plot::Disc;
use BenchLite::Plot::Memory;

#---------------------------------------------------------#
#                      CONSTRUCTOR
#---------------------------------------------------------#

sub new {
    my ($class) = @_;

    #------------------------DATA-------------------------#
    my $self->{_data_}      = {};
    $self->{_R_} = ();
    $self->{_libs_} = [
      "ggplot2",
      "grid",
      "gridExtra",
      "ggpubr",
      "tidyverse",
      "scales"
    ];


    #-----------------------OUTPUT------------------------#
    $self->{_output_}       = "./";

    bless $self, $class;
    return $self;
}


#---------------------------------------------------------#
#                       Methods
#---------------------------------------------------------#


sub plot {

  my ($self,$select, $data) = @_;

  #check
  if (!$self->_check_R_libs()){
    print STDERR "Loading libraries failed!";
  };


  my $run_R = BenchLite::Plot::Runtime->new();
  my $disc_R = BenchLite::Plot::Disc->new();
  my $mem_R = BenchLite::Plot::Memory->new();


  $run_R->{_R_}  = $self->{_R_};
  $disc_R->{_R_} = $self->{_R_};
  $mem_R->{_R_}  = $self->{_R_};

  my ($r,$d,$m) = (0,0,0);
  my @runs = ();
  my @mems = ();
  my @dscs = ();
  # load data

  foreach my $plot (keys %{$select->{'plot'}}){

    if ($plot eq 'runtime'){
      my @runplots =  sort{ $a <=> $b } keys %{$select->{'plot'}->{$plot}};
      my $stop = $self->_compute_x_lab(@runplots);
      foreach my $rt_plot (@runplots){
        push(@runs, $run_R->plot(
            $r++,
            (($r>$stop)?(1):(0)),
            $select->{'plot'}->{$plot}->{$rt_plot},
            $data,
            $select->{'plot_name'}->{$plot}->{$rt_plot})
        );
      }
    }elsif ($plot eq 'disc'){
      my @discplots =  sort{ $a <=> $b } keys %{$select->{'plot'}->{$plot}};
      my $stop = $self->_compute_x_lab(@discplots);
      $disc_R->{_x_unit_} = 'B';
      $disc_R->{_y_unit_} = 'B';
      foreach my $ds_plot (@discplots){
        push(@dscs, $disc_R->plot(
            $d++,
            (($d>$stop)?(1):(0)),
            $select->{'plot'}->{$plot}->{$ds_plot},
            $data,
            $select->{'plot_name'}->{$plot}->{$ds_plot},
            $select->{'head'}->{flags}->{0}
            )
        );
      }
    }elsif($plot eq 'memory'){
      my @memplots =  sort{ $a <=> $b } keys %{$select->{'plot'}->{$plot}};
      my $stop = $self->_compute_x_lab(@memplots);
      foreach my $mm_plot (@memplots){
        push(@mems, $mem_R->plot(
            $m++,
            (($m>$stop)?(1):(0)),
            $select->{'plot'}->{$plot}->{$mm_plot},
            $data,
            $select->{'plot_name'}->{$plot}->{$mm_plot})
        );
      }
    }else{
      print "I do not recognize $plot format\n";
    }

  }

  my @summary = ();
  # plot
  if (@runs > 0){
    $run_R->plot_summary(@runs);
    push (@summary, $run_R->get_summary_stats());
  }
  if (@dscs > 0){
    $disc_R->plot_summary(@dscs);
    push (@summary, $disc_R->get_summary_stats());
  }
  if (@mems > 0){
    $mem_R->plot_summary(@mems);
    push (@summary, $mem_R->get_summary_stats());
  }

  return $self->_make_summary_table(@summary);
}




#---------------------------------------------------------#
#                   Private Methods
#---------------------------------------------------------#



sub _make_summary_table{

  my ($self, @arg)  = @_;


  my @table = ();
  my $j = 0;

  foreach my $set (@arg){
    foreach my $tab (sort keys %{$set}){

      push (@{$table[$j]},"TableName");
      foreach my $col (sort keys %{$set->{$tab}}){
        push (@{$table[$j]},$col);
      }
      $j++;

      for (my $i = 0; $i < @{$set->{$tab}->{'Identifier'}}; $i++){
        push (@{$table[$j]},$tab);
        foreach my $col (sort keys %{$set->{$tab}}){
          push (@{$table[$j]},$set->{$tab}->{$col}->[$i]);
        }
        $j++;
      }
    }
  }
  return \@table;
}

sub _compute_x_lab {
  my ($self,@arr) = @_;

  my $stop = @arr;
  my $tr  = $stop % 3;
  return ($tr==0) ? ($stop-3) : ($stop-$tr);
}

sub _check_R_libs {

  my ($self) = @_;

  my $ok = 0;
  my $check_fn  = << "R";
  install_load <- function (package, ...)  {
    if(package %in% rownames(installed.packages()))
      do.call('library', list(package))
    else {
      install.packages(package)
      do.call("library", list(package))
    }
  }
R

  $self->{_R_}->run($check_fn);

  foreach my $lib (@{$self->{_libs_}}){
    my $line = "install_load(\'$lib\')";
    $ok = $self->{_R_}->run($line);
  }
  return  ($ok) ? (1) : (0);
}



1;
