# free-ip

Web-App for receiving a free ip-address

## Installation

```
git clone https://github.com/jfqd/free-ip.git
cd free-ip
mkdir log
bundle
cp env.sample .env
RACK_ENV=production bundle exec rake db:create
RACK_ENV=production bundle exec rake db:migrate
RACK_ENV=production bundle exec rake db:seed
```

## Configuration

Edit ```.env``` file.

## Usage

tbd.

## Hosting

We use Phusion Passenger, but you can use thin, puma, unicorn or any other rack server as well. For testing just use:

```RACK_ENV=production bundle exec rackup```

Copyright (c) 2020 qutic development GmbH