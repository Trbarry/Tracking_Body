#!/usr/bin/env perl
use strict;
use warnings;

# Print regex matches from pdftotext output with the one-based PDF page index.
# Usage: pagegrep.pl REGEX FILE...
my $pattern = shift @ARGV // die "usage: pagegrep.pl REGEX FILE...\n";
my $re = qr/$pattern/i;

for my $path (@ARGV) {
    open my $fh, '<:raw', $path or die "open $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh;
    my @pages = split /\f/, $text, -1;
    for my $index (0 .. $#pages) {
        my @lines = split /\R/, $pages[$index];
        for my $line_index (0 .. $#lines) {
            next unless $lines[$line_index] =~ $re;
            printf "%s\tpdf=%d\tline=%d\t%s\n",
                $path, $index + 1, $line_index + 1, $lines[$line_index];
        }
    }
}
