#!/bin/sh
echo 'SELECT user_id,vm_state,instances.created_at,instances.updated_at,instance_type_id,uuid,project_id,display_name FROM instances WHERE instances.deleted_at is NULL and instances.updated_at < NOW() - INTERVAL 2 DAY ORDER BY user_id;' | \
mysql nova  | \
perl -we 'use strict; use JSON;
    my $skip=1;
    my @values=qw"state created updated flavor id project name";
    my %user;
    while(<>) {
        next if(--$skip >= 0);
        chop;
        my @a=split("\t");
        my %value=();
        for(my $i=$#values; $i>=0; $i--) {
            $value{$values[$i]} = $a[$i+1];
        }
        die if not $value{project};
        push(@{$user{$a[0]}}, \%value);
    }
    print JSON->new->canonical(1)->pretty->encode(\%user);
' > /root/usage.json
