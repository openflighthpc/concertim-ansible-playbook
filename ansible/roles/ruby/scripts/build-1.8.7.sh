#!/bin/bash

set -e

BUILD_DIR=/tmp/ruby-build.`date -u +%Y%m%d%H%M%S`
RUBY_VERSION=1.8.7-p374
RUBY_PATCHES=(
    https://raw.githubusercontent.com/rvm/rvm/master/patches/ruby/1.8.7/no_sslv2.diff
    https://raw.githubusercontent.com/rvm/rvm/master/patches/ruby/ssl_no_ec2m.patch
    https://raw.githubusercontent.com/rvm/rvm/master/patches/ruby/1.8.7/stdout-rouge-fix.patch
)

if [ $# -lt 1 ] ; then
    echo "Usage: `basename $0` PREFIX [ruby-build options]"
    exit 1
fi

# Create a temporary build directory.
mkdir -p $BUILD_DIR/patches && cd $BUILD_DIR/patches

# Download the required patches.
for patch in ${RUBY_PATCHES[@]} ; do
    wget $patch
done

# Download the Ruby tarball.
cd $BUILD_DIR
wget http://ftp.ruby-lang.org/pub/ruby/1.8/ruby-$RUBY_VERSION.tar.gz
tar xzf ruby-$RUBY_VERSION.tar.gz
cd ruby-$RUBY_VERSION

# Apply the patches
patch -R -p1 < $BUILD_DIR/patches/no_sslv2.diff
patch -p1 < $BUILD_DIR/patches/ssl_no_ec2m.patch
patch -p1 < $BUILD_DIR/patches/stdout-rouge-fix.patch

# Recreate the archive, so our installer can use it.
cd $BUILD_DIR
tar czf ruby-$RUBY_VERSION.tar.gz ruby-$RUBY_VERSION

# Create the ruby-build manifest.
echo -n "require_gcc
install_package \"ruby-$RUBY_VERSION\" \"file:///$BUILD_DIR/ruby-$RUBY_VERSION.tar.gz\" auto_tcltk standard
install_package \"rubygems-1.6.2\" \"https://rubygems.org/rubygems/rubygems-1.6.2.tgz#cb5261818b931b5ea2cb54bc1d583c47823543fcf9682f0d6298849091c1cea7\" ruby
" > 1.8.7-p374

# Install the patched Ruby (requires ruby-build).
export RUBY_CONFIGURE_OPTS
ruby-build $BUILD_DIR/$RUBY_VERSION "$@"

exit 0
