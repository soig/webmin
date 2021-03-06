# urpmi-lib.pl
# Functions for installing packages with Mageia/Mandriva urpmi
use urpm::util;

sub list_update_system_commands() {
    return "urpmi";
}

# update_system_install([package])
# Install some package with urpmi
sub update_system_install {
    my $update = $_[0] || $in{update};
    my @rv;
    my $cmd = "urpmi --force --auto";
    print "<b>", &text('urpmi_install', "<tt>$cmd $update</tt>"), "</b><p>\n";
    print "<pre>";
    &additional_log('exec', undef, "$cmd $update");
    my $qm = join(" ", map { quotemeta($_) } split(/\s+/, $update));
    &open_execute_command(my $CMD, "$cmd $qm </dev/null", 2);
    local $_;
    while (<$CMD>) {
	s/\r|\n//g;
	# FIXME: this is bogus:
	# 1) urpmi can actually print "installing pkg1 pkg2 pkg3... pkgX from"
	# 2) urpmi may not print the "from" part
	if (/installing\s+(\S+)\s+from/) {
	    # Found a package
	    my $pkg = $1;
	    $pkg =~ s/\-\d.*//;	# remove version
	    push(@rv, $pkg);
	}
	print &html_escape($_ . "\n");
    }
    print "</pre>\n";
    if ($?) {
	print "<b>$text{urpmi_failed}</b><p>\n";
	return ();
    }
    else {
	print "<b>$text{urpmi_ok}</b><p>\n";
	return &unique(@rv);
    }
}

# update_system_form()
# Shows a form for updating all packages on the system
sub update_system_form() {
    print &ui_subheading($text{urpmi_form});
    print &ui_form_start("urpmi_upgrade.cgi");
    print &ui_submit($text{urpmi_update}, "update"), "<br>\n";
    print &ui_submit($text{urpmi_upgrade}, "upgrade"), "<br>\n";
    print &ui_form_end();
}

# update_system_resolve(name)
# Converts a standard package name like apache, sendmail or squid into
# the name used by urpmi.
sub update_system_resolve {
    my ($name) = @_;
    my $is_mageia = cat_('/etc/release') =~ /Mageia/;
    my %pkgs = (
		apache => $is_mageia ? 'apache' : 'apache2',
		dhcpd => 'dhcp-server',
		mysql => $is_mageia ? 'mariadb' : 'MySQL MySQL-client MySQL-common',
		($is_mageia ? (
			       openldap => 'openldap openldap-servers',
			       samba => 'samba-client samba-server',
			      ) : ()
		),
		'postgresql' => 'postgresql postgresql-server',
	       );
    return $pkgs{name} || $name;
}

# update_system_available()
# Returns a list of package names and versions that are available from URPMI
sub update_system_available() {
    my @rv;
    &open_execute_command(my $PKG, "urpmq -f --list|sort -u", 1, 1);
    map {
	/^(\S+)\-(\d[^\-]*)\-([^\.]+)\.(\S+)/ ?
	    +{ 'name' => $1,
	       'version' => $2,
	       'release' => $3,
	       'arch' => $4,
	     } : ();
    } <$PKG>;
}

