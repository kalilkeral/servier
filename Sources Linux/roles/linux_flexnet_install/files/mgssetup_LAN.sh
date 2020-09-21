#!/bin/sh
# -------------------------------------------------------------------------------------------------
# FlexNet Inventory Agent installation
# -------------------------------------------------------------------------------------------------

# Create variables used throughout this installation script
BASEDIR=/var/tmp
BEACON=cbsw2598.fr1.grs.net

# Create a secure temporary directory
TMPDIR=/var/tmp/tempdir.$RANDOM.$RANDOM.$$
( umask 077 && mkdir $TMPDIR ) || {
	echo "ERROR: mgssetup.sh could not create a temporary directory." 1>&2
	exit 1
}

# Create rollout_response answer file
cat << EOF > $TMPDIR/mgsft_rollout_response
MGSFT_BOOTSTRAP_DOWNLOAD=http://$BEACON/ManageSoftDL
MGSFT_BOOTSTRAP_UPLOAD=http://$BEACON/ManageSoftRL
MGSFT_HTTPS_CHECKSERVERCERTIFICATE=false
MGSFT_HTTPS_CHECKCERTIFICATEREVOCATION=false
MGSFT_RUNPOLICY=1
EOF

# Create custom.ini
cat << EOF > $BASEDIR/config.ini
[ManageSoft\Common]
NetworkSense=False
NetworkMinSpeed=0

[ManageSoft\NetSelector\CurrentVersion]
SelectorAlgorithm=MgsSubnetMatch
EOF

# Set owner to install or nobody or readable by all so pre 8.2.0 Solaris
# clients checkinstall script can read it.
if [ "`uname -s`" = "SunOS" ]
then
	chown install $TMPDIR/mgsft_rollout_response 2>/dev/null \
		|| chown nobody $TMPDIR/mgsft_rollout_response 2>/dev/null \
		|| chmod a+r $TMPDIR/mgsft_rollout_response
fi

# ----------------------------------------------------------------------------------------
# Move from the secure directory to the known path
ret=0
( mv -f $TMPDIR/mgsft_rollout_response /var/tmp/mgsft_rollout_response ) || ret=1
rm -rf $TMPDIR

[ $ret -ne 0 ] && {
	echo "ERROR: mgssetup.sh could not create answer files." 1>&2
	exit 1
}
# Install FlexNet Inventory Agent
echo "Installing FlexNet Inventory Agent"
rpm -ivh $BASEDIR/managesoft-*.x86_64.rpm

# Apply custom configuration from $BASEDIR/config.ini
echo "Applying custom configuration into config.ini"
/opt/managesoft/bin/mgsconfig -i $BASEDIR/config.ini

# Perform cleanup
rm -rf $BASEDIR/config.ini
