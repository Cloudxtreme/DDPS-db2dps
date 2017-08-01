
# Database to DDPS daemon, dd2dps

The following describes the _database host_ and the daemon which adds and
queries the database for new and expired rules.

## Documentation and installation procedure and a short configuration guide:

  - [DDPS database host installation](docs/README-docs.md)

## Direct link to main source code below:

  - Start here: [README](src/ddps-src/README.md)
  - Read / change [Makefile](src/ddps-src/Makefile)
  - Daemon configuration file [db.ini](src/ddps-src/db.ini)
  - Daemon source: [db2dps.pl](src/ddps-src/db2dps.pl)
  - [SQL strings](src/ddps-src/sqlstr.pm)
  - [Kill switch source](src/ddps-src/kill_switch_restart_all_exabgp.pl)

## License

DDPS is copyright 2015-2017 DeiC, Denmark

Licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
(the "License"); you may not use this software except in compliance with the
License.

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

At least the following other licences apply:

  - [PostgreSQL](https://www.postgresql.org/about/licence/) - essential an BSD license
  - [perl](https://dev.perl.org/licenses/) which also covers the used perl modules. Each license
    may be found on [http://search.cpan.org](http://search.cpan.org).

