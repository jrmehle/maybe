
<img width="1190" alt="maybe_hero" src="https://github.com/user-attachments/assets/5ed08763-a9ee-42b2-a436-e05038fcf573" />

# Maybe: The personal finance app for everyone

> [!IMPORTANT]
> This repository is a fork of [maybe-finance/maybe](https://github.com/maybe-finance/maybe), maintained by [@jrmehle](https://github.com/jrmehle). The upstream project is no longer actively maintained — you can read more in its [final release](https://github.com/maybe-finance/maybe/releases/tag/v0.6.0) — but this fork is.

## About this fork

This fork is maintained by [@jrmehle](https://github.com/jrmehle) and is primarily used to self-host the app. The intent is to keep the app running on a current platform with minimal changes to its behavior:

- Ruby 3.4.4 → 4.0.9 (see [`.ruby-version`](.ruby-version))
- Rails 7.2 → 8.1
- Dependency, devcontainer, and CI updates that came with those upgrades

## Maybe Hosting

Maybe is a fully working personal finance app that can be [self hosted with Docker](docs/hosting/docker.md).

## Attribution

This project is based on the work of [Maybe Finance](https://github.com/maybe-finance/maybe) and is **not affiliated with or endorsed by** Maybe Finance Inc. It is distributed under the same [AGPLv3 license](LICENSE) as the original project.

## Local Development Setup

**If you are trying to _self-host_ the Maybe app, stop here. You
should [read this guide to get started](docs/hosting/docker.md).**

The instructions below are for developers to get started with the app.

### Requirements

- See `.ruby-version` file for required Ruby version (currently 4.0.9)
- PostgreSQL >9.3 (ideally, latest stable version)

After cloning the repo, the basic setup commands are:

```sh
cd maybe
cp .env.local.example .env.local
bin/setup
bin/dev

# Optionally, load demo data
rake demo_data:default
```

And visit http://localhost:3000 to see the app. If you loaded the demo data, you can use the following credentials to log in:

- Email: `user@maybe.local`
- Password: `password`

For further instructions, see guides below.

### Setup Guides

These guides are from the upstream project's wiki and may reference older versions of the stack:

- [Mac dev setup guide](https://github.com/maybe-finance/maybe/wiki/Mac-Dev-Setup-Guide)
- [Linux dev setup guide](https://github.com/maybe-finance/maybe/wiki/Linux-Dev-Setup-Guide)
- [Windows dev setup guide](https://github.com/maybe-finance/maybe/wiki/Windows-Dev-Setup-Guide)
- Dev containers - visit [this guide](https://code.visualstudio.com/docs/devcontainers/containers) to learn more

## Copyright & license

This project is distributed under an
[AGPLv3 license](LICENSE). "Maybe" is a trademark of Maybe Finance, Inc.
