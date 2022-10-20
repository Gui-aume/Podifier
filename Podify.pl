#!/usr/bin/env perl

use File::Find;
use Cwd;
use File::Basename;
use File::Path 'make_path';

die('Usage: ./Podify.pl <path of project modules>') if !$ARGV[0];

my $project = $ARGV[0];

my @files = ();

sub buildLeft {
	my $hash = $_[0];
	my $path = $_[1] // '';

	my $html = '<ul>';

	foreach my $key (sort %$hash) {

		if( !$key){
			next;
		}
		
		my $link = ($path ? $path.'::' : '') . $key;
		# remove the sufix to differentiate file from dir
		$link =~ s/_pm$//;

		if ( ref($hash->{$key}) eq ref {} ) {
		# if ( scalar($hash->{$key}) > 0 ) {
			$html .= '<li>' . (split /\//, $key)[-1] . '/';
			$html .= '<ul>' . buildLeft($hash->{$key}, $link) . '</ul></li>';
		} else {
			# $key =~ s/\//::/g;
			# if (index($key, '::') != -1) {
			$entries++;
			if( ref $key ne ref {} ) {
				$key =~ s/_pm$//;
				$html .= '<li class="anchor"><a href="#' . $link . '">' . $key . '</a></li>';
			}
		}
	}

	$html .= '</ul>';

	return $html;
}


sub wanted {
	/\.pm$/s && push @files, $_;
}

# Get all dir recursively
find({no_chdir => 1, bydepth => 0, wanted => \&wanted}, $project);

my $pwd = getcwd;
my $packages = ();
my $all = ();
my $allSubs = ();

# Read all the ".pm" files
foreach $file (@files) {
	open FILE, $file;

	my $package;
	my @subs = ();

	while(<FILE>) {
		if( /^\s*package\s*([^;]+);/s ) {
			$package = $1;
			my $filePath = $1;
			# replace '::' by '/' for navigation
			$filePath =~ s/::/\//gs;
			
			my ($name, $dirPath) = fileparse($filePath);

			$packages->{$package} = $filePath;

			my $newPath = $pwd . '/html/' . $dirPath;

			if(!-d $newPath) {
				make_path $newPath or die 'Failed to create path: ' . $!;
			}

			# Build the tree for left menu
			my $string = '$all';

			my @dirs = split /::/, $package;
			@dirs[-1] .= '_pm'; # to differenciate packet from directory

			foreach my $dir (@dirs) {
				$string .= "->{$dir}";
			}
			$string .= " = '$packages->{$key}';";
			eval $string;

			# Generate the pod file
			system('pod2html --podpath='.$project.' --infile='.$file.' --outfile='.$newPath.$name.'.html');
		}
		# Add the sub declaration to the list
		elsif( /^\s*sub\s*([^{]+){/s ) {
			push @subs, $1;
		}
	}

	$allSubs->{$package} = \@subs;

	close FILE;
}

# Build the left menu recursively
my $leftMenu = buildLeft($all);

####
# Build the page content

my $contentOutput = '';

foreach my $key ( sort (keys %$packages) ) {

	$contentOutput .= "<li id='$key'><a href='$packages->{$key}.html'>$key</a><ul>";

	foreach my $sub (sort @{$allSubs->{$key}}) {
		$contentOutput .= "<li>$sub</li>";
	}

	$contentOutput .= '</ul></li>';
}

open INDEX, '>', $pwd.'/html/index.html';
print INDEX <<END;
<html>
<head>
	<style>
		li { list-style: none; padding: .2em 0; }
		body { display:flex; }
		* { margin: 0;}
		#left { display:flex; flex-direction: column; position: fixed; overflow-y: scroll; height: 100vh; }
		#left a { text-decoration: none; }
		#left a:hover { text-decoration: underline; }
		#searchField { margin: 0 1em; }
	</style>
</head>
<body>
<div id='left'>
	<input id='searchField' type='text' /> 
	$leftMenu
</div>
<div id='right'>
	<ul>
		$contentOutput
	</ul>
</div>
</body>
<script>
let modules;

const search = () => {
	const input = document.querySelector('#searchField').value

	modules.forEach(li => {
		li.style.display = li.firstChild.text.toLowerCase().includes(input.toLowerCase()) ? 'block' : 'none'
	})
}

document.addEventListener("DOMContentLoaded", () => {
	// Set the padding from the left menu width
	const width = document.querySelector('#left').offsetWidth
	document.querySelector('#right').style.paddingLeft = width + 10

	//modules = document.querySelectorAll('#left li')
	modules = document.querySelectorAll('.anchor')

	document.querySelector('#searchField').addEventListener('input', search)
})

</script>
</html>
END

close INDEX;