# Chef License Acceptance Flow

[![Gem Version](https://badge.fury.io/rb/license-acceptance.svg)](https://badge.fury.io/rb/license-acceptance)

This repo consists of a few parts:

1. A specification for the acceptance of the new [Chef EULA](https://www.chef.io/end-user-license-agreement/)
    1. The [Trademark](https://www.chef.io/trademark-policy/) page contains useful information, especially for users who
       have questions about building an open source fork of Chef Software products.
1. A Ruby library used for accepting the license
1. A Golang library intended to be used by a Habitat package for accepting the license

> All items in a quote block are pending TODOs that we will solve.

## Specification

1. Users of Chef products must have a positive confirmation of the Chef license before using each Chef product.
    * Positive confirmation flow - the idea that, to use any Chef Product, the user must have an interaction with that
      product and make some effort to accept the license. That could take the form of an interactive prompt on the
      command line, a web page in a browser that requires a user to click an 'accept' button, writing a confirmation
      flag into a config file, passing a confirmation flag on the command line or something else.
    * There is no organization-level acceptance, only user-level acceptance. Users in an organization who accept the
      license accept it for the entire organization.
1. Multiple products can be accepted in a single license acceptance flow.
1. If the license is not accepted the product will exit with code `172`.
    * This is a randomly chosen number that enables CI tools to handle license failures with specific behavior.
1. If a local product has accepted licenses and it installs a product onto a remote machine, the set of existing accepted
   licenses should be transferred to the remote machine. If the remote machine needs to accept new product licenses it
   should prompt for that acceptance on the local machine.
    * For example, users install the ChefDK and accept the license for ChefDK, Chef Client, InSpec, etc. If the user
      runs `knife bootstrap` against a remote machine then the licenses from the local machine will be copied to the
      bootstrapped machine. This prevents having to accept those licenses on the new machine.
    * Local products only copy across licenses for the products being installed on the remote machine. For example, a
      developer has accepted the ChefDK and Chef Client licenses on their workstation. When they use `knife bootstrap`
      to install Chef Client on a remote machine only the Chef Client license would be copied over, not the ChefDK
      license.
    * If a local product installs a new product on the remote machine that does not have a local license the local
      product will prompt the user to accept the new license on the local machine. For example, imagine a user has
      accepted the license for Inspec locally but no other licenses. The user creates a remote machine with Test Kitchen
      and installs Chef Client on the remote machine. Before trying to run Chef Client on the remote machine Test
      Kitchen should take the user through a license acceptance flow locally, persist the accepted Chef Client license,
      and transfer it to the remote machine. This license should be persisted and used for all future Chef Client runs,
      locally or remotely. Non acceptance should fail the Test Kitchen converge.
1. Chef products will persist the license acceptance so users are not required to accept the license on every use.
    * Note: The products will *attempt* to persist this information but some product usage (EG, on ephemeral machines)
      cannot be persisted. Non-persistance will not cause the product to fail, but it does mean users would need to
      accept the license on next product usage.
1. New product component installs will need to have their license accepted.
    * Example: a user is running A2 and has accepted the A2 license. Then the user installs the Workflow product into
      their existing A2 installation. Before they can use that Workflow product they need to accept the license for it.
    * If the install a new component that is not considered a new 'product', they would not need to accept a license for
      that.
1. The license content is available at https://www.chef.io/end-user-license-agreement/. Existing Chef users will need to
   accept this license to upgrade to any product released after this license goes into effect. Existing product releases
   will be bound by existing licenses (EG, users can continue to use Chef Client 14 without accepting the new license).
1. Chef Software will provide tools and guidance on how to accept this license ahead of upgrading products so customers
   can avoid outages and pain that could result from upgrading and being denied usage without understanding why.

## Product List
<!---
https://www.tablesgenerator.com/markdown_tables#
-->
| Client Products  | Server Products       | Remote Management Products     |
|------------------|-----------------------|--------------------------------|
| Chef Client      | Automate 2            | Knife                          |
| Chef Workstation | Chef Backend          | Terraform Habitat Provisioner  |
| ChefDK           | Chef Server           |                                |
| Habitat binary   | Habitat Build Service |                                |
| InSpec           | Habitat Supervisor    |                                |
| Push Jobs Client | Push Jobs Server      |                                |
|                  | Supermarket           |                                |

In addition the following products embed other products:

* kitchen-inspec -> inspec
* chef-infra -> audit-cookbook -> inspec
* A2 -> chef-client -> audit-cookbook -> inspec
* > ...

These top level products will need to present the license for both the top level product and all embedded products for
user acceptance.

## Client Products

Client products are ones installed and ran by users. This is in contrast to server products which are installed and ran
by automation and/or supervisors.

### Ruby Client Products

Ruby based client products can all be updated to match this specification by incorporating a shared library. This
library will be loaded by command line executables (EG, `chef-client`, `knife`, `inspec`, etc.) and used to enforce a a
common UX for license acceptance.

![](docs/client.png)

The above diagram illustrates the UX flow of client side Ruby products.

The standard exit code of 172 is there to allow automated machines to detect a license acceptance failure and deal with
it appropriately. Developers who consume this library can handle the exit logic differently but we recommend exiting 172
to keep a consistent experience among all Chef Software products.

See the [Ruby README](./components/ruby/README.md) for developer notes on consuming this library.

### Acceptance Values and Precedence

Users accept the license by passing one of the following options. The `silent` options suppress any output on STDOUT.
The `no-persist` options means the license marker file will not attempt to be persisted to the filesystem.

* `--chef-license accept`
* `--chef-license accept-no-persist`
* `--chef-license accept-silent`
* `ENV[CHEF_LICENSE]="accept"`
* `ENV[CHEF_LICENSE]="accept-no-persist"`
* `ENV[CHEF_LICENSE]="accept-silent"`

Additionally consumers of this library can manually provide an acceptance value. See the [Ruby README](./components/ruby/README.md#configuration) for details on how to provide this value.

This library uses the following precedence order:

1. If `accept-no-persist` value is provided via any means (from caller, command line argument, environment variable) then the acceptance check will pass with no output.
1. Existing marker files will attempt to be read. If all required marker files for the checked product are found then the acceptance check will pass.
1. If `accept-silent` value is provided via any means then the acceptance check will pass with no output. Acceptance will attempt to be persisted.
1. If `accept` value is provided via any means then the acceptance check will pass and echo this on STDOUT. Acceptance will attempt to be persisted.
1. If STDIN is a TTY then the interactive prompt will be ran.  Acceptance will attempt to be persisted.
1. If none of these checks succeed then the application will exit with code 172.

### License File Persistence

If the user accepts the license a marker file is deposited at `#{ENV[HOME]}/.chef/accepted_licenses/`. These marker
files prevents the user from getting prompted for license acceptance on subsequent runs. Currently we write some
metadata to that file. However, when checking to see if the user has already accepted the license only the presence of
the file matters. It can be completely empty. We hypothesize that the metadata may become useful in the future.

When writing the license marker file different locations are used for different users:

* On *nix OS
    * If the user is root: `/etc/chef/accepted_licenses/`
    * If the user is non-root: `#{ENV[HOME]}/.chef/accepted_licenses/`
* On Windows OS
    * If the user is Administrator: `%HOMEDRIVE%:\chef\accepted_licenses` (typically `C:\chef\accepted_licenses\`)
    * If the user is not Administrator try the following root paths and use the first found (typically `C:\Users\<username>\.chef\accepted_licenses`):
        1. `%HOME%` - typically not defined in Windows.
        1. `%HOMEDRIVE%:%HOMEPATH%` - typically `C:\Users\<username>` but may not exist if defined as an unavailable
           network mounted drive.
        1. `%HOMESHARE%:%HOMEPATH%` - could refer to a shared drive.
        1. `%USERPROFILE%` - typically `C:\Users\<username>`.

When reading the license file non-`Administrator`/`root` users will look in the `Administrator`/`root` location if it is
not found in their default location. This pattern has the side effect that users could accept licenses as the
`Administrator`/`root` user ensure the license is present for all users on the machine.

### Habitat Client Product

The `hab` binary has been updated to match the same license acceptance UX documented here. Because it is written in Rust
it cannot leverage a shared library but has the same functionality and UI. The `hab` binary stores its license file in a
different location than other software in the Chef Software ecosystem:

* On *nix:
    * If the user is root: `/hab/accepted_licenses/`
    * If the user is non-root: `~/.hab/accepted_licenses/`
* On Windows:
    * If the user is Administrator: `C:\hab\accepted-licenses\`
    * If the user is not Administrator: `C:\Users\<username>\.hab\accepted-licenses\`

Similar to the Chef license locations, non-`Administrator`/`root` users will look in the `Administrator`/`root` location
if it is not found in their default location.

The only licenses stored here will be for the Habitat products (`hab`, Habitat Builder, etc.).

Client products (Chef Client, InSpec, etc.) that have a license acceptance flow will _not_ try and expose that flow via
`hab pkg install`. For these products Habitat operates much like a package manager. The license acceptance flow will be
triggered when the user tries to use the product. This is different from server products which will be covered below.

## Server Products

Server products are different from client products in that users typically mange them with a process manager. Because of
this there are less opportunities to inject a license acceptance flow. License failures may not be obvious to the user
except by seeing the service fail to start, which is not an ideal UX. We therefore try to have the user accept the
license when they try to *manage* the service.

There are two broad types of server products we manage - omnibus packaged products and hab packaged/managed products.

### Omnibus Managed Products

All our omnibus managed products use some form of the `omnibus-ctl` command to manage the installation. We will inject
the license acceptance flow into these commands. The configuration command is required to successfully run the product.
This should prevent users from running the application in a meaningful way without encountering the license acceptance
flow.

In addition to the supported configuration methods in the client flow the server can be configured with a custom
`omnibus.rb` configuration file. The flow therefore is updated to:

![](docs/server.png)

See the [License File Persistence](#license-file-persistence) section for information on how the license is persisted.
The omnibus-ctl commands require customers to run as the `root` user so licenses are persisted to the
`/etc/chef/accepted_licenses` directory.

Omnibus managed products can leverage the shared library in the `license-acceptance` gem to facilitate the license
acceptance flow.

### A2

A2 currently has a command line tool to install and configure it, much like Omnibus packaged applications do. This tool
will be updated to follow the same UX we use for those Omnibus products. The license can be accepted during configuration;
later the license can be accepted during reconfiguration for new components.

### Hab managed products

Hab managed products will use a pattern similar to the one implemented in the [MLSA](https://github.com/chef/mlsa)
project. This is a package that, when included as a dependency, will prevent a service from running unless the user has
set a configuration flag saying they accept the license agreement. See the [enclosed
README](./components/golang/habitat/README.md) for details on implementation.

These Habitat managed services will not have an interactive prompt based flow like the client products do. We feel this
is acceptable because server products are typically managed by a supervisor process instead of a user.

This Habitat service will not attempt to do product verification or persistence. It is a very simple binary check. In
the future we may modify this to be more like the Ruby managed services but it complicated the Automate deployment case
so we leave that for a later date.

## Remote Management Products

Chef Software produces a variety of products that manage remote machines (Test Kitchen, `knife bootstrap`, `chef run`,
etc.). These products will be updated to copy any local licenses to the remote machines they manage. For example, if a
user has accepted the Chef Client license and uses `knife bootstrap` to bootstrap a remote node, the acceptance will be
copied to that remote node. This prevents `knife bootstrap` from failing to run Chef Client because of a missing
license.

Remote management products will also allow license acceptance as part of remote management configuration. Let us assume
the user is running Test Kitchen without accepting the license for Chef Client. If they use Test Kitchen to converge a
remote node then Test Kitchen will take the user through the interactive license acceptance flow for the Chef Client
license. Once accepted it will be stored locally and copied to the remote machine.

Users will also be able to customize the product to automatically accept the license instead of prompting. To continue
the Test Kitchen example we will add an optional configuration option. Users could populate their `kitchen.yml` with:

```yaml
provisioner:
  name: chef_zero
  accept_license: true
```

That will automatically accept the Chef Client license locally and send it to all subsequent machines it converges.
Because it will have accepted it locally for the current user it does not need to always be in the configuration.

### Terraform Habitat Provisioner

The [Terraform Habitat Provisioner](https://www.terraform.io/docs/provisioners/habitat.html) covers a wide variety of licenses to potentially be accepted. Users only need to install Terraform but install habitat and any habitat packages on remote machines. Licenses for both habitat and any installed packages need to be accepted locally. This can be done in the following ways:

1. In the Terraform config:
```
resource "aws_instance" "redis" {
  count = 3

  provisioner "habitat" {
    peer = "${aws_instance.redis.0.private_ip}"
    use_sudo = true
    service_type = "systemd"
    accept_license = ["habitat", "core/redis"]

    service {
      name = "core/redis"
      topology = "leader"
      user_toml = "${file("conf/redis.toml")}"
    }
  }
}
```
1. If the required licenses are present locally they will automatically be copied over to the remote machine.
1. License acceptance can be accepted as an environment variable to support CI workflows. EG, `ENV[TERRAFORM_HABITAT_LICENSE_ACCEPT]="habitat,core/redis"`

Accepting the license as part of the Terraform config will attempt to persist the license locally so it would not need
to be accepted in subsequent runs. The license can be seeded locally using the [Bulk License Acceptance
Tools](#bulk-license-acceptance-tools) so they are present before attempting to use the Terraform Habitat Provisioner.

### Packer

> TODO - Packer is used to bake chef-client and post-converge state into images

### Effortless Infrastructure

Effortless Infrastructure is a habitat based approach for deploying cookbooks and InSpec profiles. Users are able to
adjust configuration via Habitat config (`default.toml`, `user.toml`, `hab config apply`, etc.). Habitat is responsible
for running `chef-client` or `inspec` to converge/scan the infrastructure. This requires accepting the EULA.

Chef Software will present the same UI/UX to users as other Habitat managed products (EG, Chef Server). Users will need
to set the Habitat config as described in the [README](./components/golang/habitat/README.md#your-configuration).

## Upgrade Guidance for Customers

There will be marketing and sales education internally to ensure our staff is ready to help customers through this
transition. To enable this we will produce tools to help customers prepare ahead of time so they experience the least
amount of frustration.

### Bulk License Acceptance Tools

> TODO need to get some time with UX on these

We will produce two tools for users to accept licenses for multiple products in one invocation. There are a few purposes
for this. The first is that it allows users to accept licenses before upgrading to product versions that would ask for a
license. This prevents user frustration through this license change. Secondly it will allow Habitat users to accept
licenses for multiple Habitat packages with a better UX than [`hab config apply`](#hab-managed-products). It can also be
used by external tools (like the [Terraform Habitat Provisioner](#terraform-habitat-provisioner)) to accept licenses.

Invoking both of the following tools will present the user with a similar UX, bridging our experience across our product
lines. It will know about supported Chef Software products and fail if the user tries to accept a license for an unknown
product.

`chef license` will be used for all non-habitat products. Invoking it will take users through the same interactive
prompt based flow that using a client product would. It will also have options to accept via a flag, where to persist
licenses, etc. It can be used to accept licenses for multiple products. Examples:

```
chef license accept chef inspec
chef license accept chef-workstation --persist-location C:\mounted_dir\chef
chef license list # List the licenses that have and can be accepted
```

`hab license` will be used to accept the license for Habitat products as well as any Habitat packaged Chef products.
This means it can accept the license for the `hab` binary and a package like `chef/chef-server`. Invoking it will also
take users through the same interactive prompt based flow unless they accept the license as part of the invocation. It
can also accept a license for running Habitat services. Examples:

> TODO what configuration will we need to point it to running services?

```
hab license accept # accepts the license for the hab binary only
hab license accept chef/chef-server chef/push-jobs-server
hab license list --read-paths /etc/hab/accepted_licenses/
hab license list --running # Show running habitat services that have not accepted a license
```

### Chef Client installs

We will produce a cookbook (or modify an existing one) that allows users to accept a license before upgrading to Chef
Client 15. When applied and converged on their fleet it will create the license persistence markers. The upgrade to Chef
Client 15 should then be seamless and not fail due to missing licenses.

### Chef Ingredient cookbook

Knows how to install and manage omnibus packaged products.
> Is this the same as the section above?

### Other Environments

There are bound to be other paths users follow to package, deploy and configure chef products. We will update these
tools to support the new license requirements. Our criteria should be that users can accept the license for product(s)
with the least amount of resistance possible while still ensuring they have gone through a positive license acceptance
flow.

## License

**License:**: Apache License, Version 2.0

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
# Copyright

See [COPYRIGHT.md](./COPYRIGHT.md).
