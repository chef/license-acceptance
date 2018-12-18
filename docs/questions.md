require 'license_acceptor'
LicenseAcceptor.check('chef', Chef::Version)

-- expose command line args for the help text

question - how do we decide to persist license acceptance into /etc or ~/.chef ?

question - if we're not on a tty, how do we log? We have different logging classes based on our applications.

Do we want to have a unique exit code if they don't or cannot accept the license? This could potentially help CI, but seems like something thats going to need user involvement anyways.

Seems like we want a non-interactive custom exit code so that tools like Test Kitchen can introspect the lack of acceptance from chef client and give users a nice error message.

For chef - do we need to add license acceptance to _all_ the binaries? Or just `chef-client` and `knife`?
