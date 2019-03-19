pkg_name=license-acceptance
pkg_origin=chef
pkg_version=0.1.0
pkg_description="TODO: Chef Online Master License and Services Agreement"
pkg_upstream_url="TODO: https://www.chef.io/online-master-agreement"
pkg_maintainer="Chef Software Inc."
pkg_license=('Apache-2.0')
pkg_bin_dirs=(bin)

pkg_build_deps=(
  core/go
)

# pkg_scaffolding=core/scaffolding-go
# scaffolding_go_base_path=github.com/chef
# scaffolding_go_repo_name=a2
# scaffolding_go_import_path="${scaffolding_go_base_path}/${scaffolding_go_repo_name}/components/${pkg_name}"
# scaffolding_go_build_tags=(netgo)
# scaffolding_go_binary_list=(
#   "${scaffolding_go_import_path}/cmd/${pkg_name}"
#   "${scaffolding_go_import_path}/cmd/inspec_runner"
# )

do_build() {
  $(pkg_path_for core/go)/bin/go get -u golang.org/x/vgo
  $(pkg_path_for core/go)/bin/vgo build -o bin/accept ./pkg/accept.go
}

do_install() {
  install -m 0755 "${SRC_PATH}/bin/helloworld" "${pkg_prefix}/bin"
  # fix_interpreter "${pkg_prefix}/bin/accept" core/busybox-static bin/env
}
