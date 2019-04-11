pkg_name=license-acceptance
pkg_origin=chef
pkg_version=0.2.6
pkg_description="Chef End User License Agreement Acceptance"
pkg_upstream_url="https://www.chef.io/end-user-license-agreement/"
pkg_maintainer="Chef Software Inc."
pkg_license=('Apache-2.0')
pkg_bin_dirs=(bin)

pkg_build_deps=(
  core/go
  core/git
)

do_build() {
  $(pkg_path_for core/go)/bin/go build -o bin/chef-license ./*.go
}

do_install() {
  install -m 0755 "${SRC_PATH}/bin/chef-license" "${pkg_prefix}/bin"
}

do_setup_environment() {
  set_runtime_env CHEF_LICENSE_CONFIG "${SRC_PATH}/config/config.toml"
  set_runtime_env CHEF_LICENSE_PRODUCT_INFO "${SRC_PATH}/config/product_info.toml"
}
