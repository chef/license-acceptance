#!/bin/sh
#
# After a PR merge, Chef Expeditor will bump the PATCH version in the VERSION file.
# It then executes this file to update any other files/components with that new version.
#

set -evx

sed -i -r "s/^(\s*)VERSION = \".+\"/\1VERSION = \"$(cat VERSION)\"/" components/ruby/lib/license_acceptance/version.rb
cd components/ruby
bundle update
cd ../..
sed -i -r "s/^pkg_version=.+\$/\pkg_version=$(cat VERSION)/" components/golang/habitat/plan.sh

# Once Expeditor finshes executing this script, it will commit the changes and push
# the commit as a new tag corresponding to the value in the VERSION file.
