# Chef EULA
See the [README](../../README.md) for an overview of the license-acceptance project. This README contains the Golang
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

### default.toml
```toml
[chef_license]
acceptance = "undefined"
```

### run hook
```sh
#!/bin/sh
set -e
# Call the script to fail the service if the user has not accepted the license
{{pkgPathFor "chef/license-acceptance"}}/bin/chef-license {{cfg.chef_license.acceptance}} {{pkg.origin}}/{{pkg.name}} {{pkg.version}}
```

### Your Configuration
```toml
[chef_license]
acceptance = "accept"
```

`acceptance` is the only required configuration for the application to work, but there are other optional configurations:

```toml
[chef_license]
acceptance = "accept"
persist_path = "/root/"
read_paths = ["/root/", "/home/ubuntu/"]
persist = false
```

* `persist_path` - Location on filesystem where license marker files should be persisted. This path must be in the
  `read_paths` for the marker files to be read later. Defaults to `"/etc/chef/accepted_licenses"` for root user or
  `"$HOME/.chef/accepted_licenses"` for non root user. No path expansion is performed.
* `read_paths` - List of locations to look for license acceptance files that were written at `persist_path`. Defaults to
  `["/etc/chef/accepted_licenses"]` for root user or `["/etc/chef/accepted_licenses", "$HOME/.chef/accepted_licenses"]` for
  non root user. No path expansion is performed.
* `persist` - If set to `false`, do not attempt to persist license marker files. Defaults to `true`.
