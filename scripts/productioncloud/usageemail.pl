#!/usr/bin/perl -w
# input productioncloud/usagedump.sh JSON on stdin or via file:
# username: {id:X, project: Y, ... name: }
use strict; use JSON;
my $debug=1;
my $cloudname=`cat /etc/cloudname`; chomp($cloudname);
my $shortcloudname=$cloudname; $shortcloudname=~s/\.suse\.de//;
my $adminaddr=qq,bwiedemann+$shortcloudname\@suse.de,;
$/=undef; my $userdata=decode_json(<>);
foreach my $u (sort keys %$userdata) {
  foreach my $e (@{$userdata->{$u}}) { $e->{URI}="https://$cloudname/auth/switch/$e->{project}/?next=/project/instances/$e->{id}/"}
  my $userdb=`openstack --insecure user show --domain ldap_users $u --format shell`;
  $userdb=~m/^name="(.*)"$/m or next;
  my $username=$1;
  my $useremail="";
  if($u =~ m/^[0-9a-f]{50,}$/) { # LDAP ID
    $useremail=`ldapsearch -h ldap.suse.de -b dc=suse,dc=de -x uid=$username | awk '/^mail:/{print \$2}'`;
    chop($useremail);
  } else {
    $userdb=~m/^email="(.*)"$/m and $useremail=$1;
  }
  if(!$useremail) {
    warn "no email addr found for $username";
    $useremail=$adminaddr;
  }
  my $mailcmd="mail -s \"usage stats for $username on $cloudname\" -R $adminaddr $useremail";
  if($debug) {
    open(MAIL, ">&STDOUT");
    print MAIL "mailcmd: $mailcmd\n";
  } else {
    open(MAIL, "|$mailcmd");
  }
  print MAIL "Dear $username,
this is an automated email from your cloud operator to inform you that
you currently have the following instances on $cloudname.
If they are not needed, please delete them.

When using the cloud, do not forget that VMs may be lost to hardware failures.
If you care about it, make external backups of your data,
setup and configuration! A volume snapshot can already help.

###
", JSON->new->canonical(1)->pretty->encode($userdata->{$u});
  close(MAIL);
  last if $debug;
}
