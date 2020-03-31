use strict;
use Getopt::Long;

my ($help, $script, $limit, $out);
GetOptions ("i=s" => \$script,
            "h" => \$help,
            "x=i" => \$limit,
            "o=s" => \$out,
            );

if($help  || !$script ){
  print "Usage:\n\n";
  print "\t-i\tInput file\n";
  print "\t-x\tlimit\n";
  print "\t-o\toutput\n";
  exit(0);
}

my $limit = int(rand(3)+1) * $limit;

my $d = int($limit/10);
my @a = ();
for (my $i = 0; $i<$limit;$i++){
  if ($i%$d == 0){
     @a = ();
     sleep 1;
  }
  push(@a,$i);
}

my $tt = int(rand($d));

if ($out){
  open (O, ">", $out) || die "$!";
  print O "@a[0..$tt]";
  close O;
}else{
  print  "@a";
}

sleep 1;
