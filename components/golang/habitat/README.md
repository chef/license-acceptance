# Chef Online Master License and Services Agreement
See the [README](../../README.md) for an overview of the license-acceptance project. This component contains the Golang
implementation and notes for using it.

## Usage
To use this package you need to add it to your plan, add the key/values show below to your `default.toml`, and call it
in your `run` hook(s).

### plan.sh
```bash
pkg_name=example
pkg_origin=chef
pkg_version=0.1.0
pkg_description="My Example Service"
pkg_license=('Proprietary')
pkg_deps=(
  chef/license-acceptance
)
```

### Your Configuration
```toml
[chef_license]
acceptance = "accept"
```

### run hook
```sh
#!/bin/sh
# Call the script to fail the service if the user has not accepted the license
{{pkgPathFor "chef/license-acceptance"}}/bin/chef-license {{cfg.chef_license.acceptance}} {{pkg.origin}}/{{pkg.name}} {{pkg.version}}
```
