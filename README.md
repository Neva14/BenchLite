# BenchLite

[![License](https://img.shields.io/badge/license-GPL-blue.svg)]( )

Simple CLI benchmarking tool

Note: Major code rewriting required!

# Synopsis

To install & run:

0. Download:    

   `git clone https://github.com/RobertBakaric/BenchLite.git`

1. Unpack the BenchLite package (BenchLite-XXX.tar.gz):   

   `tar -xvzf BenchLite-XXX.tar.gz`

2. Change the current directory to BenchLite-XXX:   

   `cd BenchLite-XXX/`

3. Build the program for your system:   

   `perl Build.PL`

4. Compile the program:   

   `make`

5. Test:   

   `make test`

6. Install the program:   

	`(sudo) make install`


7. Execute:

```
  ./src/apps/bench.pl -h

  Usage:

	-i	Input script [*.bench]
	-o	Output table [tsv]
	-b	Number of times to repeat a given measurment
	-d	Time interval for memory snaps [in sec]
	-e	Print out bench template


		Execution example
		bench -o MyResults.tsv -b 3 -d 2 -i my.bench
```

Bench script example:   

```
# Plot definition:
#Function:-------Tag,------Tag-:-PlotTitle----------------#

%TagClasses:    Tool,     NGS
#---------------------------------------------------------#
%PlotRuntime:  T1/T2,      -  : First
%PlotRuntime:     T1,   HiSeq : Second
%PlotDisc:        T1,      -  : Tool1
%PlotDisc:        T2, NovaSeq : Tool2
%PlotMemory:   T1/T2,      -  : Memory



%FlagClasses: In, Out
#---------------------------------------------------------#
#
# Aplications:

# app:1
#---------------------------------------------------------#

%Tags:   T1, HiSeq
%Flags:   -i,>

perl tool1.pl -i in -x 100  > out.1
#---------------------------------------------------------#

# app:2
#---------------------------------------------------------#

%Tags:   T2, NovaSeq
%Flags:   -i,-o


tool2  -x 100 -i in -o out.1
#---------------------------------------------------------#

```



# Description

Benchmarking is the practice of comparing processes and performance metrics to
industry standard best practice solutions. Parameters typically considered
during measurement process are:

a) quality of the resulting output,
b) execution time
c) memory usage
d) disc usage

"bench" is a simple cli application that utilizes all of the above stated quantifiations
schemas and crunches out a simple descriptive statistical summary for a set of measurements
obtained from direct cli app executions

# Author

	Robert Bakaric <robertbakaric@zoho.com>
	Neva Skrabar <neva.skrabar@gmail.com>

# License



	#  Copyright 2020 Robert Bakaric & Neva Skrabar
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


# TODO

1. break big methods
2. write documentation
3. write POD
4. finish shell
5. finish get()
6. rewrite the Core
7. reorganize the code to achieve better modularity
9. fix png plot
10. write latex extension
11. finish Buld.PL
12. add PCA analysis
13. replace regex parser with a proper interpreter
14. replace fork with thread
99. etc.
