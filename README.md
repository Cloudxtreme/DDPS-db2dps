
# Administrating Database Rules, and fastnetmon instances

The following describes the installation of the  _database host_ and
the daemons for rule- and fastnetmon administration.

## Daemons

  - **db2dps** rule administration: announce and withdraw rules
    and add rules from fastnetmon to the database.
  - **fnmcfg** fastnetmon administrration: add, edit and delete
    fastnetmon instances, manage and install configuration changes.       
    Check that the expected status for all fastnetmon instances matches
    the real status (up/down, service and vpn running etc), check the
    number flow spec announcements matches the expected status in the
    database.

## Command line tools

  - **apply-default-rules**: apply a set of default rules preventing most
    volumetric DDoS attacks.
  - **ddpsrules**: command line add, delete and view rules
  - **edit_authorized_keys**: add fastnetmon ssh keys to both _database hosts_
  - **kill_switch_restart_all_exabgp**: ExaBGP kill switch (both)

## Installation, development, etc

**Test and deployment**: See [README in vagrant](vagrant/README.md)
[vagrant](https://www.vagrantup.com/intro/index.html) and
[virtualbox](https://www.virtualbox.org).       
**Source**: See [README in source/ddps-src](src/ddps-src/README.md)

## Documentation and configuration etc:

  - [Design overview](docs/ddps-design-short.md)
  - [Installation](docs/install.md)
  - [db2dps documentation](docs/db2dps-documentation.md)
  - [General documentation](docs/README-docs.md)

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

