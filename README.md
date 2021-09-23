# Biblivre

Biblioteca Livre Internacional - an open source library management system and OPAC: www.biblivre.org.br

## Build and deploy

There are basically two ways to build and deploy:
1. using Docker and Docker Compose; and
2. installing the dependencies manually in your system.

1\. is the easiest way as it only requires setting up Docker and Docker Compose, while 2\. gives you more control over the system parts and also makes the database persistent by default. However 2\. is trickier to perform, revert the changes and start over when compared to 1\., so we won't provide step by step instructions for it.

### Dependencies
To build and deploy it's necessary to have in your system
1. JDK (version 8 or newer)
1. Maven
1. Docker
1. Docker Compose

### Docker Compose

#### Running Biblivre

After installing the dependencies, download or clone (using git) this repository. If you download the repository, extract the zip file in a known folder.

On the project root folder, run `mvn clean verify -P docker -Ddockerfile.skip=true`.
It will take around 5 minutes, but it depends on the processing power of the computer and the available Internet bandwidth to download dependencies if needed. After all deploy process is done, you can access Biblivre at `localhost:8080/Biblivre6`. The application server is running in debug mode, so you can debug the application remotely via port 8000.

#### Configurations

The following variables are used in Biblivre and can be set on the .env file:

* `APP_HTTP_HOST_PORT` (HTTP access port to Biblivre app; default: 8080)
* `APP_DEBUG_HOST_PORT` (debug port (JPDA); default: 8000)
* `POSTGRES_PASSWORD` (password for the database; default "abracadabra")
* `POSTGRES_DB` (database name; default "biblivre4")
* `DATABASE_HOST_PORT` (database host port; default: 5432)
* `DATABASE_HOST_NAME` (database hostname; default: "database", which is also the hostname of the container that hosts PostgreSQL)
