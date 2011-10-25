#!/usr/bin/perl
 
use strict;
use warnings;
use Image::ExifTool;
use File::Copy;

my $version = '1.0.1';

# If you are only using nikon .NEF files and need more precision than a second,
# modify the value of $tag to be 'SubSecCreateDate'
my $tag = 'DateTimeOriginal'; 

my @extensions = ('NEF', 'CR2', 'CRW', 'JPG');
my ($prefix, $outdir, @dirs) = @ARGV;

usage('Prefix not specified') if !defined($prefix);
usage('ouput dir not specified or doesn\'t exist') if (!defined($outdir) || !(-d $outdir));
usage('No source directories specified') if (@dirs == 0);

my %files;

foreach my $dir(@dirs) {
    scanDir($dir);
}

# Figure out how many images we have, then figure out how many digits we need to
# represent in the filename
my $imageCount = keys %files;
my $numDigits  = length($imageCount);

my $count = 0;
foreach my $file(sort {$files{$a} cmp $files{$b}}  keys %files) {
    my @pieces = split(/\./, $file);
    my $extension = $pieces[@pieces - 1]; 
    my $newfile = sprintf("%s/%s_%0${numDigits}s.%s", $outdir, $prefix, $count, $extension);

    printf("Copying %s to %s\n", $file, $newfile); 
    copy($file, $newfile);

    $count++;
}

sub scanDir {
    my ($dir) = @_;

    opendir(my $dh, $dir) || die("Unable to read directory $dir\n");
    while(my $file = readdir $dh) {
        my $matched = 0;

        for(my $i=0; $i<@extensions && !$matched; $i++) {
            if($file=~m/$extensions[$i]$/i) {
                $matched = 1;
                $files{"$dir/$file"} = getTag("$dir/$file", $tag);
            }
        }
    }
    closedir $dh;
}

sub getTag {
    my ($file, $tag) = @_;

    print "Reading file $file\n";

    my $exifTool = new Image::ExifTool;
 
    $exifTool->Options(Unknown => 1);
    my $info = $exifTool->ImageInfo($file);

    return $info->{$tag};
}

sub usage {
    my ($msg) = @_;

    print "ERROR: $msg\n\n";
    print `perldoc $0`;
    exit(1);
}

=head1 NAME

order_cron.pl - A script to chronologically order files from multiple cameras 

=head1 SYNOPSIS

order_cron.pl prefix outdir indir1 indir2 ... indirN
 
=head1 DESCRIPTION

This script chronologically orders files from all of the input directories based
on the embedded timestamp in the EXIF data. Copies all files into the output
directory.

=over 4

=item B<prefix>

What to prefix the file names with in the output dir. For example, if you want
files to be named something like jills_wedding_001.NEF, then set prefix to
jills_wedding

=item B<outdir>

The path (relative or absolute) to the output directory where you want the
files to end up.

=item B<indir1 ... indirN>

The relative or absolute path to any number of input directories.

=back

=head1 CHANGE LOG

1.0.1  Adding support for multiple file extensions, changing the EXIF tag
       used to DateTimeOriginal to be more compatible across camera makes
       and models

1.0    Initial release

=head1 AUTHORS

Copyright (C) 2011 Jason Hancock http://geek.jasonhancock.com

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
