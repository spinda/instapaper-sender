# instapaper-sender

*Basic HTTP gateway to save articles to Instapaper*

[![Hackage](https://img.shields.io/hackage/v/instapaper-sender.svg)](https://hackage.haskell.org/package/instapaper-sender)
[![Hackage-Deps](https://img.shields.io/hackage-deps/v/instapaper-sender.svg)](http://packdeps.haskellers.com/feed?needle=instapaper-sender)

## Intro

`instapaper-sender` provides an web server that will take URLs and send them to
Instapaper via email. This makes it easier to add articles to your reading list
from devices that lack an Instapaper app, for example, the Kindle.

Note that the web service runs ***unauthenticated***: if someone finds your
server address, they can add whatever they want to your reading list!

## Build

Install [Stack](http://haskellstack.org/) and run `stack build`.

## Usage

Obtain an email account on a service that supports SMTP with SSL (for example,
[Yandex Mail](https://mail.yandex.com)).

Copy the included `config.example.json` and fill out the settings:

```
{
  "http": {
    "port": <port for the HTTP server to listen on>
  },
  "smtp": {
    "host": "<SMTP host to connect to>",
    "port": <SMTP port to connect on>,
    "username": "<SMTP username to authenticate with>",
    "password": "<SMTP password to authenticate with>",
    "from": "<email address for the From field>"
  },
  "instapaper": {
    "email": "<your unique Instapaper email address>"
  }
}
```

All fields are mandatory. The Instapaper email address for your account can be
found on [this page](https://www.instapaper.com/save/email).

Start the server, via `stack exec -- instapaper-sender` or by setting up the
compiled executable as a daemon (see the sample
[systemd unit file](/instapaper-sender.service)).

`instapaper-sender` expects to
be forwarded requests from a reverse proxy setup like
[Nginx](http://nginx.org/) (see the sample
[Nginx configuration](/instapaper-sender.nginx)). It will look for the forwarded
IP address in the HTTP headers when producing log output.

Once you're all set up, navigate to
`http://<your instapaper-sender address>/<url>` to send `<url>` to your reading
list.

## License

Copyright (C) 2017 Michael Smith &lt;michael@spinda.net&gt;

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
