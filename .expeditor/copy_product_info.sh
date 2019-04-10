#!/bin/sh
#
# We need to copy the top level product_info.toml into the two distributions (habitat and gem)
#

set -evx

echo "# DO NOT CHANGE - overwritten by expeditor at build time" > components/ruby/config/product_info.toml
cat product_info.toml >> components/ruby/config/product_info.toml
echo "# DO NOT CHANGE - overwritten by expeditor at build time" > components/golang/habitat/config/product_info.toml
cat product_info.toml >> components/golang/habitat/config/product_info.toml

# Once Expeditor finshes executing this script, it will commit the changes and push
# the commit.
