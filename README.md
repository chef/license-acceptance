# Chef License Acceptance Flow

# Specification

1. Users of Chef products must have a positive confirmation of the Chef license before using each Chef product.
  * > What about organization acceptance vs user acceptance?
  * Positive confirmation flow - the idea that, to use any Chef Product, the user must have an interaction with that
    product and make some effort to accept the license. That could take the form of an interactive prompt on the
    command line, a web page in a browser that requires a user to click an 'accept' button, writing a confirmation
    flag into a config file, passing a confirmation flag on the command line or something else.
1. Multiple products can be accepted in a single license acceptance flow.
1. If a tool is ran on a system that has accepted licenses and it installs a product onto a remote system, the set
   of existing license acceptances should be transfered to the remote system. If the remote system needs to accept
   new product licenses it should prompt for that acceptance on the originating system.
   * For example, users install the ChefDK and accept the license for ChefDK, Test Kitchen, Inspec, etc. If the user
     runs Test Kitchen and creates a remote system that installs Chef then the licenses from the originating machine
     should be copied to the new machine. This prevents having to accept those licenses on the new machine.
   * If Test Kitchen installs a new product on the remote machine (EG, Habitat) then Test Kitchen should prompt the user
     to accept the habitat license on the originating machine. It should persist this acceptance and then copy it over
     to the remote machine as well as any subsequent machines.
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
| Inspec           | Habitat Supervisor    |                                |
| Push Jobs Client | Push Jobs Server      |                                |
|                  | Supermarket           |                                |


> Software that uses software as a library:
> * kitchen-inspec -> inspec
> * chef-client -> audit-cookbook -> inspec
> * A2 -> chef-client -> audit-cookbook -> inspec
> * ...

## Client Tools

### Ruby Client Tools

Ruby based client-side tools can all be updated to match this specification by incorporating a shared library. This
library will be loaded by command line executables (EG, `chef-client`, `knife`, `inspec`, etc.) and used to enforce a
a common UX for license acceptance.

For developers to consume this library, add the following lines to your executable's startup:

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

![](docs/client.png)

The above diagram illustrates the UX flow of client side Ruby tools.

If the user accepts the license a marker file is deposited at `#{ENV[HOME]}/.chef/accepted_licenses/`. These marker
files prevents the user from getting prompted for license acceptance on subsequent runs. Currently we write some
metadata to that file. However, when checking to see if the user has already accepted the license only the presence of
the file matters. It can be completely empty. We hypothesize that the metadata may become useful in the future.

> Do we want to have a unique exit code if they don't or cannot accept the license? This could potentially help CI,
> but seems like something thats going to need user involvement anyways. Seems like we want a non-interactive custom
> exit code so that tools like Test Kitchen can introspect the lack of acceptance from chef client and give users a
> nice error message.

### Habitat client tools

The `hab` binary has been updated to match the same license acceptance UX documented here. Because it is written in
Rust it cannot leverage a shared library but has the same functionality and UI.

> What about client packages (EG, Inspec) installed by Habitat? Do we just capture those tools the same way or do we
> enable hab to pass through a license acceptance? Do we limit these packages with some kind of thing like the MLSA?

## Remote Management Tools

> TODO

## Server Tools

Server tools are different from client tools in that users typically mange them with a process manager. Because of this
there are less opportunities to inject a license acceptance flow. License failures may not be obvious to the user except
by seeing the service fail to start, which is not an ideal UX. We therefore try to have the user accept the license
when they try to *manage* the service.

> Do we want to have a service lock that causes the service start to fail if the management tool has not been ran?
> Without a lock, we avoid failure conditions users may not be expecting. But is this okay if they somehow avoid
> running the management tool? This should not be possible for any of our known products but someone could somehow
> avoid running `chef-server-ctl reconfigure` if they manually configure the server themselves.

> Users upgrading are required to run `chef-server-ctl reconfigure` to trigger data migrations, but there is nothing
> today that *requires* them to do this. Maybe a requirement of running a `reconfigure` command on upgrade would be
> enough to meet our requirements?

There are two broad types of server side tools we manage - omnibus packaged tools and hab managed tools.

### Omnibus managed products

All our omnibus managed products use some form of the `omnibus-ctl` command to manage the installation. We will inject
the license acceptance flow into these commands. All the products require some kind of configuration command to run
before the product will start. That should prevent users from running the application in a meaningful way without
encountering the license acceptance flow.

The one difference from the client products is that the server products also contain a user managed configuration file
where the license can be accepted. The flow therefore is updated to:

![](docs/server.png)

Another difference from the client products is the server products typically run as some kind of service user. Because
of this we should persist the license acceptance files to `/etc/chef/license_acceptance/` instead of `#{ENV[HOME]}/.chef/accepted_licenses/`. The omnibus-ctl commands require customers to run this command as root today so we should
have write permissions to this directory, but may need to change this directory to be configurable in the future.

Omnibus managed products can leverage the shared library in the `license-acceptance` gem to facilitate the license
acceptance flow.

### Hab managed products

> Need to talk with someone from the Habitat team to determine how this flow will work. Ideally we can enforce the
> license acceptance flow at `hab service start` time, and accepting it via the hab utility will transfer the license
> storage files to the managed service so any service locks are avoided.

> How does persistence for an ephimeral service work? Do we just require users to pass the equivalent of
> `--accept-license` every time they start a service?

> https://github.com/chef/mlsa contains prior art we should leverage. May possible update this library or clone it
> into the current repo and leverage it for all habitat managed products?

> Whatever we decide needs to, ideally, work for both client tools and server tools managed via habitat.

## Windows

> TODO: any special notes about Windows tools



















## Installation

Add this line to your application's Gemfile:

```ruby
gem 'license-acceptance'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install license-acceptance

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/license-acceptance.
