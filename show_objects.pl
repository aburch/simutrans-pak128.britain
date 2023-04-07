#!/usr/bin/perl

#
# show_objects.pl
#   by William Lindley, wlindley@wlindley.com 
#   Copyright (c) 2009-2014 and released under the GNU General Public License version 2.0
#   
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# DESCRIPTION:
#
# Displays a variety of reports about the objects in the Simutrans pak.
#
# For each commodity
#   Scan through the range of years
#      Print a flow diagram of industries that involve the commodity
#
# Vehicle performance statistics
# 
# Vehicle timeline consistency check

#
# [-t translation_file]   Use translation file; e.g., path to en.tab
# [-r pak_source_dir]     Recursively process all *.dat files in and below given directory
#
use strict;
use Getopt::Std;
getopts('t:r:v');
use Data::Dumper;

use v5.20;
use feature qw(signatures);
no warnings qw(experimental::signatures);

my $verbose = $::opt_v;

my $lang_code;
my $lang_name;

my $translate_from;
my %translation;

#print Dumper(\%translation);

sub translate ($word) {
    return (exists $translation{lc($word)} ? $translation{lc($word)} : $word);
}

sub read_translate_file ($filename) {
    open TRANSLAT, '<', $filename or die "Can't open translation file $filename\n";
    while (<TRANSLAT>) {
	chomp;
	if (/^\s*#(.*)$/) {
	    my $comment_text = $1;
	    if ($comment_text =~ /\blanguage\s*:\s*(\w+)\s(\w+)/i) {
		($lang_code, $lang_name) = ($1, $2);
		print "($lang_code) ($lang_name)\n";
	    }
	} elsif (/\S{1,}/) { # if anything non-blank
	    if (defined $translate_from) {
		$translation{$translate_from} = $_;
		# print "($translate_from) -> ($_)\n";
		undef $translate_from;
	    } else {
		$translate_from = lc($_);
	    }
	}
    }
    close TRANSLAT;
}

#print translate('bretter');

sub filter_object ($obj) {

    $obj->{'retire_year'} ||= 2999;
    $obj->{'retire_month'} ||= 12;

    # Permit second-level sorting for objects with equal introductory times
    my $power = $obj->{'engine_type'};
    $power = '~~~' if (!length($power)); # sort last

    $obj->{'sort_key'} = sprintf("%4d.%02d %s %4d.%02d",
				 $obj->{'intro_year'}, $obj->{'intro_month'},
				 $power,
				 $obj->{'retire_year'}, $obj->{'retire_month'});

    # Abbreviate loquacious names
    $obj->{'short_name'} = $obj->{'name'};
    if (length($obj->{'short_name'}) > 30) {
	$obj->{'short_name'} =~ s/-([^-]{3})[^-]+/-$1/g;
    }

    if (exists $obj->{'intro_year'}) {
	foreach my $period (qw[intro retire]) {
	    $obj->{$period} = $obj->{$period.'_year'} * 12 + $obj->{$period . '_month'};
	}
    }

    return $obj;
}

my %object;

sub accumulate_object_definition_line ($line) {
    state %this_object;

    if ($line =~ /^\s*(?<object>\w+)\s*(?:\[(?<sub1>\w+)\](?:\[(?<sub2>\w+)\])?)?\s*=\s*(?<value>.*?)\s*\Z/) {
	my ($object, $value, $sub1, $sub2) = @+{qw(object value sub1 sub2)};
	if (defined $sub1) {
	    # my $subb = defined $sub1 ? "[$sub1]" . (defined $sub2 ? "[$sub2]" : '') : '';
	    # print "  [$object]$subb = [$value]\n";

	    # If we have both: "value=50" and "value[0]=50", the later will clobber the former.
	    if (ref(\$this_object{lc($object)}) eq 'SCALAR') {
		undef $this_object{lc($object)};
	    }
	    if (defined $sub2) {
		$this_object{lc($object)}{lc($sub1)}{lc($sub2)} = $value;
	    } else {
		$this_object{lc($object)}{lc($sub1)} = $value;
	    }
	} else {
	    if (lc($object) eq 'obj') {
		# Accumulate previous factory into database
		if (defined $this_object{'name'}) {
		    # print "------------------------\n";
		    filter_object(\%this_object);
		    %{$object{$this_object{'name'}}} = %this_object;
		    %this_object = ();
		}
	    }
	    $this_object{lc($object)} = $value;
	    # print "  [$1] = [$3]\n";
	}
	# TEST
	my $x = Dumper(%this_object);
	if ($x =~ /HASH/) {
	    die "aaaaaa";
	}
    }
}

# Conversion note
# 1 km =  0.62137119 miles



use Data::Dumper;

use File::Find::Rule;
use Mojo::Path;

my $xlat_file = $::opt_t;
my $language = 'en';  # Default language

if ($::opt_r) {
    
    # create a new pak object.
    # name it based on the last part of the path
    # 

    # use File::Find to read in all *.dat files at or below that directory
    my @files_list = File::Find::Rule->file()->name('*.dat')->readable->in($::opt_r);
    # print join("\n",@files_list);

    # If no translation file, select one from the text/ directory.  
    # Available languages can be identified from the glob <??.tab> there.

    my $xlat = Mojo::Path->new($xlat_file);
    if (! $xlat_file) {
	$xlat = Mojo::Path->new($::opt_r);
	push @$xlat, 'text',  "${language}.tab" if defined $xlat;  # e.g., 'text/en.tab'
    }

    read_translate_file($xlat) if scalar $xlat;

    foreach my $filename (@files_list) {
	open( my $fh, '<', $filename ) or die "Can't open $filename: $!";
	print STDERR "** Processing $filename\n" if $verbose;
	while ( my $line = <$fh> ) {
	    accumulate_object_definition_line($line);
	}
	close $fh;
	accumulate_object_definition_line('obj=dummy'); # flush trailing object. no 'name=x' so can't be saved.
    }
} else {

    # new pak object named 'default'

    if ($xlat_file) {
	read_translate_file($xlat_file);
    }

    while (<>) {   # should be <<>> with Perl v5.22
	accumulate_object_definition_line($_);
    }
    accumulate_object_definition_line('obj=dummy'); # flush trailing object. no 'name=x' so can't be saved.
}


#
#
#

{

    foreach my $object_name (keys %object) {
	if ($object{$object_name}{"intro_year"} < 100) {
	    print "   $object_name  is an internal object\n";
	}

    }

    print '-'x70 . "\n";
}

{
    my %chronology;

    foreach my $object_name (keys %object) {
	next if $object{$object_name}{"intro_year"} < 100;  # Ignore pakset internals
	foreach my $event (qw(intro retire)) {
	    my $show_date = sprintf("%4d-%02d", $object{$object_name}{"${event}_year"}, $object{$object_name}{"${event}_month"});
	    my $event_key = "${show_date}-$event-$object{$object_name}{'short_name'}";

	    my @notes;
	    if (defined $object{$object_name}{'speed'}) {
		if (! ref $object{$object_name}{'speed'} ) {
		    push @notes, "speed $object{$object_name}{'speed'}";
		}
	    }
	    if (defined $object{$object_name}{'payload'}) {
		push @notes, "capacity $object{$object_name}{'payload'}";
	    }
	    if ($event eq 'retire') {
		push @notes, "introduced $object{$object_name}{'intro_year'}";
	    }
	    my $note = scalar @notes ? ' (' . join(', ',@notes) . ')' : '';
	    $chronology{$event_key} = sprintf("%-10s: %-10s %-10s %s",
					      $show_date,
					      $event eq 'intro' ? 'Introduce' : 'Retire',
					      $object{$object_name}{'obj'},
					      translate($object{$object_name}{'short_name'} . $note),
		);
	}
    }

    foreach my $happening (sort keys %chronology) {
	print "$chronology{$happening}\n";
    }
}

#
#
#

my %commodity;
my $year_lower = undef;
my $year_upper = undef;

foreach my $factory_name (sort { $object{$a}->{'sort_key'} cmp $object{$b}->{'sort_key'} } keys %object) {
    my $factory = $object{$factory_name};

    next unless ($factory->{'obj'} eq 'factory');

    # NOTE: Relies on filter_object() above to fill default times
    my $intro_year = $factory->{'intro_year'} * 12 + $factory->{'intro_month'} - 1;
    if (!defined($year_lower) || $intro_year < $year_lower) {
	$year_lower = $intro_year;
    }
    my $retire_year = $factory->{'retire_year'} * 12 + $factory->{'retire_month'} - 1;
    if (!defined($year_upper) || $retire_year > $year_upper) {
	$year_upper = $retire_year;
    }

    foreach my $direction ('input', 'output') {
	next unless defined $factory->{$direction.'good'};
	my %good = %{$factory->{$direction.'good'}};
	while (my ($commodity_key, $commodity_name) = each (%good)) {
	    my $commodity_level = $factory->{'inputcapacity'}{$commodity_key};
	    # print "$commodity_name $commodity_level\n";
	    
	    for my $year ($intro_year .. $retire_year) {
		push @{$commodity{lc($commodity_name)}{$year}{$direction}}, \$factory;
	    }
	}
    }

}

my %commodity_overview;

foreach my $commodity_name (sort keys %commodity) {
    my $this_commodity = \%{$commodity{$commodity_name}};

    my %goods_flow;
    foreach my $year ($year_lower .. $year_upper) {
	if (defined $commodity{$commodity_name}{$year}) {
	    foreach my $direction ('input', 'output') {
		foreach my $factory (@{$commodity{$commodity_name}{$year}{$direction}}) {
		    push @{$goods_flow{$year}{$direction}}, $$factory->{'name'};
		    # print "COMMODITY: $commodity_name $year $direction $$factory->{'name'}\n";
		}
	    }
	}
    }
    print "\n### $commodity_name ###\n";
    my ($last_inputs, $last_outputs);

    foreach my $year (sort {$a <=> $b} keys %goods_flow) {

	my ($inputs, $simple_inputs, $outputs, $simple_outputs);

	if (defined $goods_flow{$year}{'input'}) {
	    $inputs = join(',', @{$goods_flow{$year}{'input'}});
	    foreach my $c (@{$goods_flow{$year}{'input'}}) {
		$c =~ s/\d+//;
		$commodity_overview{$commodity_name}{'input'}{$c} = 1;
	    }
	}
	if (defined $goods_flow{$year}{'output'}) {
	    $outputs = join(',', @{$goods_flow{$year}{'output'}});
	    foreach my $c (@{$goods_flow{$year}{'output'}}) {
		$c =~ s/\d+//;
		$commodity_overview{$commodity_name}{'output'}{$c} = 1;
	    }
	}
	if ($outputs ne $last_outputs || $inputs ne $last_inputs) {
	    my $print_year = int($year/12) . "-" . (($year % 12) + 1);
	    print " $print_year: $outputs --> $inputs\n";
	    $last_outputs = $outputs;
	    $last_inputs = $inputs;
	}
    }
}

#print Dumper(%commodity_overview);

foreach my $c (sort { translate($::a) cmp translate($::b) } keys %commodity_overview) {
    print ( exists $translation{lc($c)} ? $translation{lc($c)} : $c );
    print ': ' .
	join(',',sort map { translate($_) } keys %{$commodity_overview{$c}{'output'}}) . ' -> ',
	join(',',sort map { translate($_) } keys %{$commodity_overview{$c}{'input'}}) . "\n";
}

my %factory_overview;

foreach my $c (sort keys %commodity_overview) {
    foreach my $out_werk (keys %{$commodity_overview{$c}{'output'}}) {
	#$commodity_overview{translate($c)}{translate($out_werk)} = 'out';
	$factory_overview{translate($out_werk)}{translate($c)} = 'out';
    }
    foreach my $in_werk (keys %{$commodity_overview{$c}{'input'}}) {
	#$commodity_overview{translate($c)}{translate($in_werk)} = 'in';
	$factory_overview{translate($in_werk)}{translate($c)} = 'in';
    }
}

if (scalar keys %factory_overview) {

    print "[table]\n";
    print "[tr][td][b]Industry[/b][/td][td][b]Requires[/b][/td][td][b]Produces[/b][/td][/tr]\n";
    foreach my $werk (sort keys %factory_overview) {
	my @in_goods = grep {$factory_overview{$werk}{$_} eq 'in'} keys %{$factory_overview{$werk}};
	my @out_goods = grep {$factory_overview{$werk}{$_} eq 'out'} keys %{$factory_overview{$werk}};
	print '[tr][td]' . translate($werk) . ": [/td][td]";
	if (scalar @in_goods) {
	    #print "   accepts: " . join (',', @in_goods) . "\n";
	    print join (', ', map { translate($_) } @in_goods) . "\n";
	}
	print "[/td][td]";
	if (scalar @out_goods) {
	    #print "   produces: " . join (',', @out_goods) . "\n";
	    print join (', ', map { translate($_) } @out_goods) . "\n";
	}
	print "[/td][/tr]\n";
    }
    print "[/table]\n";

    print Dumper(%factory_overview);
}

#
# Show trains (actually all vehicles: buses, ships,...)
#


{
    my $header_shown = 0;

    foreach my $train_name (sort { $object{$a}->{'sort_key'} cmp $object{$b}->{'sort_key'} } keys %object) {
	my $train = $object{$train_name};

	next unless ($train->{'obj'} eq 'vehicle');
	if (!$header_shown++) {
	    print "Rolling Stock Table.\n";
	    print "Availability--- -Power- -Type-    ---Name-------------------   -Wght- Capy -Speed-\n";
	}

	my $waytype = $train->{'waytype'};
	$waytype =~ s/_track//;
	$waytype =~ s/track/train/;
	$waytype =~ s/water/ship/;
	$waytype =~ s/narrowgauge/narrow/;

	my $capacity = $train->{'payload'} ? sprintf("%3du", $train->{'payload'}) 
	    : ' -- ';
	printf("%4d.%02d-%4d.%02d %-8s %-8s %-30s %3d%s %4s %3dkm/h\n",
	       $train->{'intro_year'}, $train->{'intro_month'}, 
	       $train->{'retire_year'}, $train->{'retire_month'}, 
	       $train->{'engine_type'}, $waytype,
	       translate($train->{'short_name'}), $train->{'weight'}, "T",
	       $capacity, $train->{'speed'}
	    );
    }
}

{
    my $header_shown = 0;

    foreach my $train_name (sort {
	$object{$a}->{'sort_key'} cmp $object{$b}->{'sort_key'} } keys %object) {

	my $train = $object{$train_name};

	next unless ($train->{'obj'} eq 'vehicle');
	next unless ($train->{'power'});

	if (!$header_shown++) {
	    print "\n\n";
	    print "Cost / Performance Table.\n";
	}

#    printf("%4d.%02d-%4d.%02d %-30s %3d %5d %5d %5d\n",
	printf("%4d.%02d,%4d.%02d,%-30s,%3d, %5d, %5d, %5d\n",
	       $train->{'intro_year'}, $train->{'intro_month'}, 
	       $train->{'retire_year'}, $train->{'retire_month'}, 
	       translate($train->{'short_name'}),
	       $train->{'weight'},
	       $train->{'power'},
	       $train->{'tractive_effort'}, 
	       $train->{'speed'},
	    );
    }
}

# Process by sort-key, which should be in order of introduction

print "Timeline consistency check\n";

use List::MoreUtils qw(any uniq);

sub has_constraint ($object_key, $type, $desired) {
    # Verifies that the object has a constraint of the named type with the desired value
    my @constraints = values %{$object{$object_key}{constraint}{$type}};
    return 1 if scalar @constraints == 0; # unconstrained
    return (any { $_ eq $desired } (@constraints)) # as desired
      || (any { lc($_) eq 'any' } (@constraints)) # or 'any'
      || (any { lc($_) eq 'none' } (@constraints)); # or 'none'
}

foreach my $train_name (sort {
    $object{$a}->{'sort_key'} cmp $object{$b}->{'sort_key'} } keys %object) {

    my $train = $object{$train_name};

    next unless ($train->{'obj'} eq 'vehicle');

    my @constraints = qw(next prev);

    my @events;
    my %vehicle_event;

    if (exists $train->{constraint}) {

	foreach my $c (0..1) {
	    my ($from, $to) = ($constraints[$c], $constraints[1 - $c]);
	    if (! has_constraint($train_name, $from, 'none')) {
		foreach my $from_obj (values %{$train->{constraint}{$from}}) {
		    next if lc($from_obj) eq 'none';

		    if (!defined $object{$from_obj}) {
			print "** $from_obj is not defined; it is required as a constraint of $train_name.\n";
		    }
		    foreach my $event (qw[intro retire]) {
			push @events, $object{$from_obj}{$event};
			push @{$vehicle_event{$event}{$object{$from_obj}{$event}}}, $from_obj;

			# print "$from_obj ${event}s in " . $object{$from_obj}{$event} ."\n";

		    }

		    print " ** $train_name has $from of $from_obj, but $from_obj does not have $to of $train_name.\n"
		      unless has_constraint($from_obj, $to, $train_name);
		}
	    }
	}

	# Replay vehicle-set timeline
	push @events, $train->{intro}, $train->{retire};
	my @events = uniq sort {$a <=> $b} @events;

	my $unbuildable_text;

	if (defined $vehicle_event{retire} && scalar %{$vehicle_event{retire}}) {
	    # Only if at least one of our dependencies retires
	    my %available;
	    my $in_service = 0;
	    my $unbuildable = 0;
	    my $rebuildable = '';
	  EVENT:
	    foreach my $event (@events) {
		foreach my $equip (@{$vehicle_event{intro}{$event}}) {
		    $available{$equip} = 1;
		    if ($unbuildable) {
			print sprintf("${unbuildable_text} until %4d/%02d, when $equip becomes available${rebuildable}.\n", 
				      $event / 12, $event % 12);
			$unbuildable = 0;
			$rebuildable = '';
		    }
		}
		foreach my $equip (@{$vehicle_event{retire}{$event}}) {
		    $available{$equip} = 0;
		}
		if ($event == $train->{intro}) {
		    # introducing ourselves
		    $in_service = 1;
		}
		if ($event == $train->{retire}) {
		    if ($unbuildable) {
			print sprintf("${unbuildable_text} until %4d/%02d when it retires.\n", $event / 12, $event % 12);
		    }
		    last EVENT;
		}
		if ($in_service) {
		    if (!any {$_} (values %available)) {
			if ($event == $train->{intro}) {
			    $unbuildable_text = sprintf("In %4d/%02d, ", $event / 12, $event % 12) . 
			      " $train->{name} is introduced, is unbuildable because none of its constraints are available";
			    $rebuildable = '';
			} else {
			    $unbuildable_text = sprintf("In %4d/%02d, vehicles(", $event / 12, $event % 12) . 
			      join (', ', @{$vehicle_event{retire}{$event}}) .
				') retire... rendering ' . $train->{name} . " unbuildable";
			    $rebuildable = ", making $train->{name} buildable again";
			}
			$unbuildable = 1;
		    }
		}
	    }
	}

    }
}

#######################################

my @livery_notation = 'a'..'z';
push @livery_notation, 'A'..'Z';
my @livery_notations = @livery_notation;

my %found_liveries;
my %livery_notes;

foreach my $train_name (sort {
    $object{$a}->{'sort_key'} cmp $object{$b}->{'sort_key'} } keys %object) {

    my $train = $object{$train_name};

    next unless ($train->{'obj'} eq 'vehicle');

    next unless (defined $train->{'liverytype'});

    my @our_liveries = sort keys $train->{'liverytype'};
    foreach my $livery (@our_liveries) {
	my $livery_name = $train->{'liverytype'}{$livery};
	if (!defined $found_liveries{$livery_name}) {
	    my $n = shift @livery_notation;
	    $found_liveries{$livery_name}{'note-letter'} = $n;
	    $livery_notes{$n} = $livery_name;
	}

	if (!defined $found_liveries{$livery_name}{'intro_year'}) {
	    $found_liveries{$livery_name}{'intro_year'} =
		$train->{'intro_year'};
	}
	if ($train->{'retire_year'} > 
	    $found_liveries{$livery_name}{'retire_year'}) {
	    $found_liveries{$livery_name}{'retire_year'} =
		$train->{'retire_year'};
	}

	push @{$train->{'livery_list'}}, 
	    $found_liveries{$livery_name}{'note-letter'};
    }

    printf ("%4d %-9s %-30s  %s\n", 
	    $train->{'intro_year'},
	    $train->{'engine_type'},
	    translate($train->{'short_name'}), 
	    join(',',sort @{$train->{'livery_list'}})
	);
}

if (scalar @livery_notations) {
    print "\n\nLivery Use Table.\n";
    print "\n\nLivery notations and usage dates:\n";
}

foreach my $liv (@livery_notations) {
    next unless length($livery_notes{$liv});

    my $i = $found_liveries{$livery_notes{$liv}}{'intro_year'};
    my $r = $found_liveries{$livery_notes{$liv}}{'retire_year'};
    printf ("  %3s %-30s  %4d-%4d\n", $liv, $livery_notes{$liv}, $i, $r);
}


1;
