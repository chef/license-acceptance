# Chef EULA
See the [README](../../README.md) for an overview of the license-acceptance project. This README contains the Ruby
implementation and notes for using it.

## Usage

For developers to consume this library, add the following lines to your executable's startup:

```ruby
require 'license_acceptance/acceptor'
LicenseAcceptance::Acceptor.check_and_persist!('inspec', Inspec::VERSION)
```

This method performs the license acceptance flow documented in the root README. If the user declines or cannot accept
the license for some reason it prints a simple message to stdout and exits with code 172. If a developer wishes to
customize this behavior they can instead add the following:

```ruby
require 'license_acceptance/acceptor'
begin
  LicenseAcceptance::Acceptor.check_and_persist('inspec', Inspec::VERSION)
rescue LicenseAcceptance::LicenseNotAcceptedError
  # Client specific implementation of how to handle the missing license
  # Could be logging to stdout or a log file then existing, but is up
  # to the client to handle appropriately
  puts "InSpec cannot execute without accepting the license"
  exit 172
end
```

The library also includes a helper to add a command line flag that customers can pass:

```ruby
require "license_acceptance/cli_flags/mixlib_cli"
...
include LicenseAcceptance::CLIFlags::MixlibCLI
```

```ruby
require "license_acceptance/cli_flags/thor"
...
include LicenseAcceptance::CLIFlags::Thor
```

## Configuration

The `Acceptor` class allows optional configuration to be passed when invoking it:

```ruby
LicenseAcceptance::Acceptor.check_and_persist('inspec', Inspec::VERSION,
  output: $stdout,
  logger: Inspec::Log,
  license_locations: ["/license_dir1", "/license_dir2"],
  persist_location: "/license_dir",
  persist: true,
  provided: "accept-no-persist",
)
```

* `output` - Output stream for license interactions, defaults to `$stdout`
* `logger` - Ruby logger device for developer logs, defaults to nil
* `license_locations` - Array of locations to search for existing licenses, defaults described in top level README
* `persist_location` - Location to persist license marker files, should be one of the locations from `license_locations`
  if future reads are supposed to work
* `persist` - Whether to persist the license marker files, setting is overwritten by `accept-no-license` acceptance
  value.
* `provided` - Acceptance value provided by the consumer of this library. Expected to be one of the supported values
  (`accept`, `accept-silent`, `accept-no-persist`) or it is ignored. Defaults to nil.
