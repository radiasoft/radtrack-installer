#!/usr/bin/env perl
use warnings;
use strict;
my($lines) = [`vagrant global-status --prune 2>&1`];
local($/) = undef;
foreach my $line (@$lines) {
    chomp($line);
    # vagrant writes blanks at the end of the line
    $line =~ s/\s+$//;
    next
        unless $line =~ m{default +virtualbox +\w+ +(/.+)}
        && -d $1;
    my($dir) = $1;
    next
        unless open(IN, "$dir/Vagrantfile")
        && <IN> =~ m{vm.box\s*=\s*"(?:biviosoftware|radiasoft)/radtrack"}im;
    next
        unless chdir($dir);
    print(STDERR "Deleting: $dir\n");
    system(qw(vagrant destroy --force));
    # Only remove directory if vagrant isn't running and only a few files
    if (@{[glob('*')]} > 5 || `vagrant status 2>&1` =~ /\bdefault\s+running\b/) {
        print(STDERR "$dir: not removing VM directory (>5 files)\n");
        next;
    }
    chdir($ENV{HOME});
    system(qw(rm -rf), $dir);
}

system(qw(vagrant box remove biviosoftware/radtrack));
system(qw(vagrant box remove radiasoft/radtrack));

exit(0);
