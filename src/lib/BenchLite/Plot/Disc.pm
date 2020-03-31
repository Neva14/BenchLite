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
package BenchLite::Plot::Disc;
#---------------------------------------------------------#
#                     Libraries
#---------------------------------------------------------#

use strict;
use warnings;
use Data::Dumper;
use Array::Utils qw(:all);
#---------------------------------------------------------#
#                      CONSTRUCTOR
#---------------------------------------------------------#

sub new {
    my ($class) = @_;

    my $self->{_R_}  = ();
    $self->{_x_scale_} = '-';
    $self->{_y_scale_} = '-';
    $self->{_x_unit_}  = 'MB';
    $self->{_y_unit_}  = 'MB';

    $self->{_x_unit_div_}  = 1_000_000;
    $self->{_x_unit_div_}  = 1_000_000;

    $self->{_summary_stats_} = ();

    $self->{_IMG_} = 'all';

    bless $self, $class;
    return $self;
}



#---------------------------------------------------------#
#                      Get
#---------------------------------------------------------#


sub get_summary_stats {

  my ($self) = @_;

  return $self->{_summary_stats_};
}


#---------------------------------------------------------#
#                      R code
#---------------------------------------------------------#

# note to myself : edit check-pl to include R dependencies

sub plot {

  my ($self,$s,$p,$lines,$data,$title,$cats) = @_;

    # make plot function

    $self->_set_globals();

    #make x-y axis
    my @name  = ();
    my @yval  = ();
    my @ysd   = ();
    my @xval  = ();
    my @xcat   = ();


    foreach my $line (@{$lines}){
      my @selection =();
      for (my $i=0; $i < @{$line}; $i++){
        my @sel = ();
        for(my $j = 0; $j< @{$data->{'disc'}->{'logic'}}; $j++){
          if ($data->{'disc'}->{'logic'}->[$j]->[$i] eq $line->[$i] || $line->[$i] eq '-'){
            push (@sel, $j);
          }
        }
        if (@selection > 0) {
          my @isect = intersect(@selection, @sel);
          @selection = @isect;
        }else{
          @selection =@sel;
        }
      }
      foreach my $l (sort {$a<=>$b} @selection){
        push(@name,join("_", @{$data->{'disc'}->{'logic'}->[$l]}));
        push(@yval, $data->{'disc'}->{'data'}->[$l]->[0]/$self->{_y_unit_div_});
        push(@yval, $data->{'disc'}->{'data'}->[$l]->[2]/$self->{_y_unit_div_});
        #push(@ysd, $data->{'disc'}->{'data'}->[$l]->[1]/$self->{_y_unit_div_});
        #push(@ysd, $data->{'disc'}->{'data'}->[$l]->[3]/$self->{_y_unit_div_});
        my $cat = sprintf("%.2f", (($data->{'disc'}->{'data'}->[$l]->[0]/$self->{_y_unit_div_}/
                               $data->{'disc'}->{'data'}->[$l]->[2]/$self->{_y_unit_div_})*100) );

        push(@xval, $cats->[0], $cats->[1]);
        push(@xcat, "$cat\%", "$cat\%");

      }
    }

    #set data vectors

    my $x = "IO.Ratio";
    my $y = "FileSize";
    my $group_by = "Identifier";

    $self->{_R_}->set("$group_by", \@name);
    $self->{_R_}->set("$y", \@yval);
    $self->{_R_}->set("$x\_cat", \@xcat);
    $self->{_R_}->set("$x", \@xval);
    #$self->{_R_}->set("$x\_sd", \@xsd);

    $self->{_summary_stats_}->{$title} = {
        $group_by => \@name,
        $x => \@xval,
        $y => \@yval,
        "$y\_cat" => \@xcat
      };

    # plot vectors in series of 3's
    $self->{_R_}->run("data_io <- data.frame($group_by, $x\_cat, $x, $y)");

    $self->{_R_}->run(
      $self->_make_plot_obj(
        $x, $y, $group_by, "$x (\%)","$y ($self->{_y_unit_})", "$title", $s, $p
      )
    );

    $self->{_R_}->run("d$s <- make_io_plot(data_io)"); #


  return "d$s";

}


sub plot_summary {

  my ($self, @arg) = @_;

  my $col = (@arg % 3);
  my $row = int(@arg / 3) + 1;
  my $width = $col * 4;
  my $highth= $row * 4;

  my $in = join(",", @arg);

  my $Rcode = << "R";
  dd <- ggarrange($in, ncol=$col, nrow=$row, align = \"v\", common.legend = TRUE, legend=\"bottom\")
  df <- annotate_figure(dd,top = text_grob(\"IO Analyses\", face = \"bold\", size = 16))
R
if ($self->{_IMG_} eq 'svg' || $self->{_IMG_} eq 'all'){
  $Rcode .= << "R";
  svg(\"IO.svg\",width=$width, height=$highth)
  df
  dev.off()
R
}
if ($self->{_IMG_} eq 'pdf' || $self->{_IMG_} eq 'all'){
  $Rcode .= << "R";
  pdf(\"IO.pdf\",width=$width, height=$highth)
  df
  dev.off()
R
}
if ($self->{_IMG_} eq 'png' || $self->{_IMG_} eq 'all'){
  $Rcode .= << "R";
  png(\"IO.png\")
  df
  dev.off()
R
}

  $self->{_R_}->run($Rcode);

}

## move this to utility -------------------------------------------------------------------------------------##

sub _set_globals{

  my ($self) = @_;

  if ($self->{_x_unit_} eq 'B'){
    $self->{_x_unit_div_} = 1;
  }elsif($self->{_x_unit_} eq 'MB'){
    $self->{_x_unit_div_} = 1_000_000;
  }elsif($self->{_x_unit_} eq 'GB'){
    $self->{_x_unit_div_} = 1_000_000_000;
  }else{
    die "_x_unit_ : $self->{_x_unit_} not properly set (B,MB,GB)\n";
  }

  if ($self->{_y_unit_} eq 'B'){
    $self->{_y_unit_div_} = 1;
  }elsif($self->{_y_unit_} eq 'MB'){
    $self->{_y_unit_div_} = 1_000_000;
  }elsif($self->{_y_unit_} eq 'GB'){
    $self->{_y_unit_div_} = 1_000_000_000;
  }else{
    die "_y_unit_ : $self->{_y_unit_} not properly set (B,MB,GB)\n";
  }


}


sub _make_plot_obj {

  my ($self,$x,$y,$group_by,$x_lab,$y_lab, $title, $s,$p) = @_;

  my $x_scale = "";
  my $y_scale  = "";
  my $annotation = "";

  $y_lab = "" if ($s % 3 == 1);
  $x_lab = "" if ($p == 0);


=pod
  if ($self->{_x_scale_} =~/log(\d+)/){
    $x_scale = "scale_x_$self->{_x_scale_}(breaks = trans_breaks(\"$self->{_x_scale_}\", function(x) $1^x), labels = trans_format(\"$self->{_x_scale_}\", math_format($1^.x))) + ";
  }else{
    $x_scale = "";
  }

  if ($self->{_y_scale_} =~/log(\d+)/){
    $y_scale = "scale_y_$self->{_x_scale_}(breaks = trans_breaks(\"$self->{_y_scale_}\", function(x) $1^x), labels = trans_format(\"$self->{_y_scale_}\", math_format($1^.x))) +";
    $annotation = "annotation_logticks() +";
  }else{
    $y_scale = "";
    $annotation ="";
  }

  #geom_text(aes(y=label_ypos, label=$x\_cat), vjust=1.6, color=\"white\", size=3.5)+
=cut
  return   << "R";

  make_io_plot <- function(tdf) {

      cmp <- ggplot(tdf, aes(x=$x\_cat, y=$y, fill=$x),sort.val = $x\_cat) +
      geom_bar(stat=\"identity\")+
      scale_fill_brewer(palette=\"Paired\")+
      labs(x = \"$x_lab\", y = \"$y_lab\", title =\"$title\")+
      theme_classic() +
      theme(plot.title = element_text(hjust = 0.5), legend.position=\"bottom\")

    return(cmp)
  }
R

}


1;
