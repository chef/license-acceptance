# Chef License Acceptance Flow

> TODO: Table of contents and introduction

# Specification

1. Users of Chef products must have a positive confirmation of the Chef license before using each Chef product.
    * Positive confirmation flow - the idea that, to use any Chef Product, the user must have an interaction with that
      product and make some effort to accept the license. That could take the form of an interactive prompt on the
      command line, a web page in a browser that requires a user to click an 'accept' button, writing a confirmation
      flag into a config file, passing a confirmation flag on the command line or something else.
    * There is no organization-level acceptance, only user-level acceptance.
1. Multiple products can be accepted in a single license acceptance flow.
1. If a tool is ran on a system that has accepted licenses and it installs a product onto a remote system, the set
   of existing license acceptances should be transfered to the remote system. If the remote system needs to accept
   new product licenses it should prompt for that acceptance on the originating system.
    * For example, users install the ChefDK and accept the license for ChefDK, Test Kitchen, InSpec, etc. If the user
      runs `knife bootstrap` against a remote system then the licenses from the originating machine
      should be copied to the bootstrapped machine. This prevents having to accept those licenses on the new machine.
    * Tools only copy across licenses for the products being installed on the remote system. For example, a developer
      has accepted the Chef Client and InSpec licenses on their workstation. When they use `knife bootstrap` to install
      Chef Client on a remote system only the Chef Client license would be copied over, not the InSpec license.
    * If a local tool installs a new product on the remote machine that does not have a local license persisted it
      should prompt the user to accept the new license on the local machine. For example, imagine a user has accepted
      the license for Test Kitchen locally but no other licenses. The user creates a remote machine with Test Kitchen
      and installs Chef Client on the remote machine. Before trying to run Chef Client on the remote machine Test
      Kitchen should take the user through a license acceptance flow locally, persist the accepted Chef Client license
      and transfer it to the remote machine. This license should be persisted and used for all future Chef Client
      runs, locally or remotely. Non acceptance should fail the Test Kitchen converge.
1. The products will persist the license acceptance so users are not required to accept the license on every use.
    * Note: The products will *attempt* to persist this information but some product usage (EG, on ephemeral machines)
      cannot be persisted.
1. This is a new license that will be released sometime in 2019. Existing Chef users will need to accept this license
   to upgrade to any product released after that time frame. Existing product releases will be bound by existing
   licenses (EG, users can continue to use Chef 14 without accepting the new license).
1. Chef Software will provide tools and guidance on how to accept this license ahead of upgrading products so customers
   can avoid outages and pain that could result from upgrading and being denied usage without understanding why.

## Product List
<!---
https://www.tablesgenerator.com/markdown_tables#
-->
| Client Tools     | Server Tools          | Remote Management Tools        |
|------------------|-----------------------|--------------------------------|
| Chef Client      | Automate 2            | Test Kitchen                   |
| Chef Workstation | Chef Backend          | Knife                          |
| ChefDK           | Chef Server           | Chef Provisioning (DEPRECATED) |
| Habitat binary   | Habitat Build Service |                                |
| InSpec           | Habitat Supervisor    |                                |
| Push Jobs Client | Push Jobs Server      |                                |
|                  | Supermarket           |                                |

In addition the following tools/products embed other products:

* kitchen-inspec -> inspec
* chef-client -> audit-cookbook -> inspec
* A2 -> chef-client -> audit-cookbook -> inspec
* > ...

These top level tools will need to present the license for both the top level tool and all embedded tools for user
acceptance.

## Client Tools

### Ruby Client Tools

Ruby based client-side tools can all be updated to match this specification by incorporating a shared library. This
library will be loaded by command line executables (EG, `chef-client`, `knife`, `inspec`, etc.) and used to enforce a
a common UX for license acceptance.

![](docs/client.png)

The above diagram illustrates the UX flow of client side Ruby tools.

For developers to consume this library, add the following lines to your executable's startup:

```ruby
require 'license_acceptance/acceptor'
LicenseAcceptance::Acceptor.check_and_persist!('inspec', Inspec::VERSION)
```

This method performs the license acceptance flow documented below. If the user declines or cannot accept the license
for some reason it prints a simple message to stdout and exits with code 210. If a developer wishes to customize
this behavior they can instead add the following:

```ruby
require 'license_acceptance/acceptor'
begin
  LicenseAcceptance::Acceptor.check_and_persist('inspec', Inspec::VERSION)
rescue LicenseAcceptance::LicenseNotAcceptedError
  # Client specific implementation of how to handle the missing license
  # Could be logging to stdout or a log file then existing, but is up
  # to the client to handle appropriately
  puts "InSpec cannot execute without accepting the license"
  exit 1
end
```

The library also includes a helper to add a command line flag that customers can pass:

```ruby
require "license_acceptance/cli_flags/mixlib_cli"
...
include LicenseAcceptance::CLIFlags::MixlibCLI
```

The standard exit code of 210 is there to allow automated systems to detect a license acceptance failure and deal with
it appropriately. Developers who consume this library can handle the exit logic differently but we recommend exiting 210
to keep a consistent experience among all Chef Software products.

#### *nix License File Persistence

If the user accepts the license a marker file is deposited at `#{ENV[HOME]}/.chef/accepted_licenses/`. These marker
files prevents the user from getting prompted for license acceptance on subsequent runs. Currently we write some
metadata to that file. However, when checking to see if the user has already accepted the license only the presence of
the file matters. It can be completely empty. We hypothesize that the metadata may become useful in the future.

If the user running is the `root` user then we write the marker file to `/etc/chef/accepted_licenses/`. On attempting
to read and see if a license has been accepted:

1. If the user is root
    1. Check in `/etc/chef/accepted_licenses/` for an accepted license
1. If the user is non-root
    1. Check in `#{ENV[HOME]}/.chef/accepted_licenses/` for an accepted license
    2. If none is found, check in `/etc/chef/accepted_licenses/`

> Question for legal: This means that users could accept product licenses as the `root` user on a system (development
> or production) and have accepted the license for all users on the system. Is this the desired behavior? Potentially
> helps companies automate license acceptance because they can pre-seed all the license acceptance for shared developer
> environments by accepting it initially as the root user. But does that violate our requirements?

#### Windows License File Persistence

Windows does not have the exact concept of a `root` user. Instead, users are granted permissions by belonging to
elevated group, commonly called `Administrator`. License marker files are stored relative to what Chef sees as a user's
home directory. The home directory is resolved by looking up the following environment variables and selecting the
first one that is a valid path:

1. `%HOME%` - typically not defined in Windows
1. `%HOMEDRIVE%:%HOMEPATH%` - typically `C:\Users\<username>` but may not exist if defined as an unavailable network mounted drive
1. `%HOMESHARE%:%HOMEPATH%` - could refer to a shared drive
1. `%USERPROFILE%` - typically `C:\Users\<username>`

Based on this logic license marker files will typically be stored to `C:\Users\<username>\.chef\accepted_licenses\`.

> If we follow the hab model, we would also read from `C:\chef\accepted_licenses`. Do we want to do that?

### Habitat client tools

The `hab` binary has been updated to match the same license acceptance UX documented here. Because it is written in
Rust it cannot leverage a shared library but has the same functionality and UI.

Client products with executables designed to be ran by users (Chef Client, InSpec, etc.) that have a license
acceptance flow will _not_ try and expose that flow via `hab pkg install`. For these tools Habitat operates much like
a package manager. The license acceptance flow will be triggered when the user tries to use the product. This is
different from server tools which will be covered below.

> Right now `hab` stores its license acceptance in `/hab`/`C:\hab` for root users and
> `$HOME/.hab`/`C:\Users\<username>\.hab` for non root users. Do we want to have this license stored to
> `/etc/chef` and `$home/.chef` instead? If we don't, both tools probably need to attempt to read from both
> locations (blegh) or the `habitat` license is written to `.hab` and all other licenses are written to `.chef`. That
> seems weird... or does it?
> https://doc.rust-lang.org/beta/std/env/fn.home_dir.html

> `hab license accept` flow is different from ruby flow. How closely do we want to match UX? Kind of mirrors last
> question. How similar do we want `hab` and the rest of the Chef Software Inc. tools to look?

> Need to look into the Habitat Terraform provisioner. That installs any Habitat package (like chef-client) using
> Habitat. Our customers are using that to bake images and we need a way for them to accept the chef license as part
> of that. Would they use the `hab license accept` tool? Or would we have them include a `chef-client --accept-license`
> and `inspec --accept-license` to their terraform definition? That seems less than ideal.

## Server Tools

Server tools are different from client tools in that users typically mange them with a process manager. Because of this
there are less opportunities to inject a license acceptance flow. License failures may not be obvious to the user except
by seeing the service fail to start, which is not an ideal UX. We therefore try to have the user accept the license
when they try to *manage* the service.

> Legal question:
> Do we want to have a service lock that causes the service start to fail if the management tool has not been ran?
> Without a lock, we avoid failure conditions users may not be expecting. But is this okay if they somehow avoid
> running the management tool?
> Users upgrading are required to run `chef-server-ctl reconfigure` to trigger data migrations, but there is nothing
> technical today that *requires* them to do this. Their service simply won't work correctly. My understanding is that
> customers do run this command on an upgrade because we tell them to do that. Is going through this 'standard flow'
> enough enforcement?

There are two broad types of server side tools we manage - omnibus packaged tools and hab managed tools.

### Omnibus managed products

All our omnibus managed products use some form of the `omnibus-ctl` command to manage the installation. We will inject
the license acceptance flow into these commands. All the products require some kind of configuration command to run
before the product will start. That should prevent users from running the application in a meaningful way without
encountering the license acceptance flow.

The one difference from the client products is that the server products also contain a user managed service
configuration file where the license can be accepted. The flow therefore is updated to:

![](docs/server.png)

See the [License File Persistence](#license-file-persistence) section for information on how the license is persisted.
The omnibus-ctl commands require customers to run as the `root` user so licenses are persisted to the
`/etc/chef/accepted_licenses` directory.

Omnibus managed products can leverage the shared library in the `license-acceptance` gem to facilitate the license
acceptance flow.

### Hab managed products

Hab managed products will use a pattern pioneered by A2 called the [MLSA](https://github.com/chef/mlsa) (Master License
Services Agreement). This is a package that, when included as a dependency, will prevent a service from running unless
the user has set a configuration flag saying they accept the license agreement. This pattern requires no changes
to habitat unless we want an interactive flow. Usage would look like the following:

```
$ hab svc load chef/chef-server --bind=database:mysql.default
$ echo 'mlsa.accept = true' | hab config apply chef-server.default 1
```

Setting `mlsa.accept = true` on the service accepts the license and allows the service to start. Multiple products
could be set by applying that config to each service group in habitat.

> This pattern would exclude the option of an 'interactive' prompt based flow where a user who has not accepted the
> license gets prompted to accept it. It instead would just prevent the services from starting. Is this something
> we care about with server products? If so, I have heard that A2 has some kind of 'interactive' flow for starting
> the service. We should investigate how that works and see if we could imbed it into the `chef/mlsa` package. Another
> option would be to enhance Habitat with some kind of pre-start hook or license acceptance hook that would allow
> user interaction in an interactive way. If we did that, the `chef/mlsa` package would become the implementation detail
> of that more generic hook. Need to talk to the Habitat team about whether this kind of enhancement makes sense.
> Already confirmed it is technically possible.

> This is currently a very different UX from the existing license acceptance flow, and also is not very user friendly.
> I propose we modify the `hab license accept` tool to manage license acceptance for products. This tool could attempt
> to persist the license file as well as setting the hab config so the mlsa is accepted. EG:
> `hab license accept chef/a2 chef/chef-client`

> We should store product list in a centralized location that all products (ruby based or hab based) can read license
> information from. Better to only have to manage this 1 place. That could probably be this repo and we could distribute
> that list in all the forms consumers need it (EG, rubygem, cargo crate, hab package, etc.)

Habitat can run services in an ephimeral environment. In this case it is not possible to persist the license acceptance
information anywhere. Rather than try to solve this problem by having customers mount a persistent drive to store
license acceptance information we recommend whatever tools they use to manage deployment simple accept the license
every time the service is started.

### A2

> TODO - is A2 going to have a common flow? Or are they in their own world with the deployment service, being able to
> configure it through the browser, etc.?

## Remote Management Tools

> TODO

> One issue we have is that someone using Habitat or Test Kitchen locally may end up needing to accept quite a lot of
> licenses to manage remote machines. We should consider some tool like `hab license accept` to accept licenses for
> an array of products in bulk. Probably something like `chef accept license --all` since Chef Workstation is
> our tool to manage all Chef Software products on user workstations.

## Upgrade Guidance for Customers

> TODO

> See note in [Remote Management Tools](#remote-management-tools) about accepting bulk licenses locally. Also need a
> way to accept licenses for fleets of pre-installed products. Breaking customers on upgrade without warning them and
> giving them tools to prevent the breakage is a non-starter.

> We REALLY need to get this information to users and customers ahead of time to make sure all these flows will work
> for them.

## Windows

> TODO: any special notes about Windows tools. Probably something about where we persist licenses acceptance information.

https://docs.chef.io/dk_windows.html#spaces-and-directories
