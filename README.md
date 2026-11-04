# Nami

`Nami` is a self-hosted personal finances and small business accounting tool to help you take control of your or your
business' finances. Powered by the latest Ruby-on-Rails technologies and SQLite.
- Have multiple ledgers to separate your concerns from personal, professional or multiple small businesses.
- Invite other people to embark in your quest for financial responsibility.
- Control who has access to which ledger in a simple and intuitive permission system.
- Upload and connect any files you need to create your own system of record for each ledger.
- Set and follow savings goals to achieve your own goals.
- Manage debts like any other account.
- Follow every cent you gain, spent or invest.
- Check your trophy room to obtain perspective of how far you've come.
- And have fun with something that sounds totally not fun at all.

## Development setup

Start with a working Rails development environment. If you haven't set one up, follow the [Rails installation guide](https://guides.rubyonrails.org/install_ruby_on_rails.html)
first. These instructions assume mise is installed and activated in your shell and libvips is available for image
processing. Docker (with Compose and Buildx) is needed only for the development container or container deployment.

From the project directory, run:

```sh
mise install
bin/setup --skip-server
```

`mise install` installs the pinned Ruby and SQLite versions. `bin/setup` installs the application gems and prepares the
local database. Run it again after pulling changes to update dependencies and apply database migrations.

Start development with:

```sh
bin/dev
```
