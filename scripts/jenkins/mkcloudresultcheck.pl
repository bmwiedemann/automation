#!/usr/bin/perl -w
use strict;
# 2015 by Bernhard M. Wiedemann
# Licensed under GPLv2

# This tool updates jenkins build descriptions with extracts from result logs

my $force=$ENV{FORCE}||0 eq "1" ?1:0;
my $jobname=$ENV{jobname}||"openstack-mkcloud";
my @buildlist=split("\n", `./japi getbuilds $jobname | sort -u -n -r | head -30`);
if($ENV{TEST}) { $force=1; @buildlist=($ENV{TEST}) }
for my $num (@buildlist) {
    my $build = "$jobname/$num";
    $_ = `curl -s https://ci.suse.de/job/$build/consoleText`;
    next if m/<body><h2>HTTP ERROR 404/;
    next unless m/Finished: FAILURE/;
    my $description=`./japi getdescription $build`;
    if($description and not $force) {
        print "skipping $build because it already has a description\n";
        next;
    }
    my $descr = "";
    foreach my $regexp (
        '(java.lang.OutOfMemoryError)',
        '(Slave went offline) during the build',
        '(Crowbar inst)allation terminated prematurely.  Please examine the above',
        'Build (timed out) \(after \d+ minutes\). Marking the build as failed.',
        '(mount.nfs: Connection timed out)',
        'Latest (SHA1 from PR does not match) this SHA1',
        '(SHA1 mismatch), newer commit exists',
        'crowbar\.(\w\d+)\.cloud\.suse\.de',
        'Error: (crowbar self-test) failed',
	'Error: Waiting for \'(all nodes to be discovered)\' timed out.',
	'Error: Waiting for \'(admin node to start ssh) daemon\' timed out.',
	'\nError: Waiting for \'([^\n\']+)\' timed out.',
	'\nError: (.+) failed',
	'\nError: (.+) failure',
	'(Automatic merge failed)',
	'(binding_failed): 1',
        'mk(?:phys)?cloud (ret=\d+)',
        '\((safelyret=\d+)\) Aborting',
        'time onadmin_(.*) failed! \(safelyret=\d+\) Aborting\.',
    ) {
        if(m/$regexp/) {$descr.="$1 "}
        $descr=~s/TIMEFORMAT="[^"]+" ; time //;
    }
    /^storage_method WARNING/m and $descr.="Not using parameter storage_method. ";
    /\+ '\[' (\d+) = 0 '\]'\n\+ exit 1\nBuild step/ and $1 and $descr.="ret=$1";
    if(/The step '(\w+)' returned with exit code (\d+)/) {
        $descr.="/$2/$1";
        if(m/Error: Committing the crowbar '\w+' proposal for '(\w+)' failed/) {$descr.="/$1"}
    }
    if(/Tests on controller: (\d+)/) {
        $descr.="/controller=$1";
        if($1 == 102) {
            if(m/RadosGW Tests: [^0]/) {$descr.="/radosgw"}
            if(m/Volume in VM: (\d+) & (\d+)/ and ($1||$2)) {$descr.="/volume=$1&$2"}
            $descr.=tempestdetails() if(m/Tempest: [^0]/);
        }
    }
    $descr ||= "unknown cause";
    if(m{^github_pr=([a-z-]+/[a-z-]+):(\d+)}mi) {
        $descr.=" https://github.com/$1/pull/$2 "
    }
    if(m{crowbar\.(v[a-z]\d|[cgh]\d)\.cloud\.suse\.de}) { $descr="$1 $descr" }
    print "$build $descr\n";
    system("./japi", "setdescription", $build, $descr);
}

sub tempestdetails {
    my $descr="/tempest";
    foreach my $regexp (
        'FAILED \((failures=\d+)\)\n\+ tempestret=',
        'FAIL: tempest\.([a-z0-9._]+)\.',
        '(ServerFault): Got server fault',
        'Cannot get interface (MTU) on \'brq',
        '(Volume) \S+ failed to reach in-use status',
        '(SSHTimeout): Connection to the',
        '(KeyError): ',
        '(MismatchError): ',
        '(AssertionError): ',
    ) {
        if(m/$regexp/) {$descr.=" $1"}
    }
    return $descr;
}
