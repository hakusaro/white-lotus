![](http://images3.wikia.nocookie.net/__cb20120930102407/avatar/images/d/dd/Order_of_the_White_Lotus_flag.png)
# White Lotus

Terraria ships with no identification system that ties Steam accounts with players. This means that players who are banned often can return with ease despite extreme lengths server owners may go to in order to prevent troublesome players from rejoining. This service unites Steam with TShock accounts, in such a way that a player is tied to their Steam account. If a player is banned from a server by SteamID, they cannot return.

## Development setup

1. Setup rvm
2. ````bundle install````
3. ````cp config.yaml.example config.yaml````
4. Edit ````config.yaml```` to point to your database (either via mysql or sqlite)
5. Assuming SQLite: ````sequel -m ./migrations/ sqlite://database.db```` to migrate the database up to the latest version.
6. ````rerun app.rb````

## Features

* Server owners can register a server and install a plugin to setup.
* Players who wish to register with a server do so on our website, which will then add the user to that server's database.
* If a player is banned, that player is flagged as such in our database, which will prevent further registrations under that Steam account.


## What Needs To Be Done

* TShock plugin is a pile of junk, needs to be redone following new web end protocol.
* Web end needs to add more error checks, and handling for errors.
* Web end and TShock plugin need to be able to communicate via rest.
  test