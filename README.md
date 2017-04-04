
# Database to DDPS daemon, dd2dps

The following describes the _database host_ and the daemon which adds and
queries the database for new and expired rules.

## The documentation is described here:

  - [Short design overview](docs/ddps-design-short.md)
  - [Installation and configuration of the database host](docs/ddps-database-server-installation.md)
  - [Documentation for the database daemon, db2dps](docs/db2dps-documentation.md)
  - [Makefile](docs/Makefile) for creating pdf and html documentation in ``docs``

## Direct link to main source code below:

  - [Makefile](src/Makefile): Makefile for everything
  - [README.md](src/README.md): Readme
  - [db.ini](src/db.ini): ini file for daemon
  - [db2dps.pl](src/db2dps.pl): daemon (perl version)
  - [md.doc](src/md.doc): some notes
  - [note.md](src/note.md): some notes
  - [todo.md](src/todo.md): a todo list

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

