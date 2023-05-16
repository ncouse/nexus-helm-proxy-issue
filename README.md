# Nexus Test Setup

This repository demonstrates an issue with Nexus when using proxied Helm repositories. It is a cut down version of a more extensive test set-up to examine the issue.

> This issue is documented in [nexus-public#138](https://github.com/sonatype/nexus-public/issues/138).

There is a Docker Compose file that starts up the necessary services, and quickly shows the issue.

This starts Nexus, and also initialises Nexus including setting up a Helm proxy repo that is pointed towards an Nginx Web server.

## Deployment

The deployment consists of a Nexus service and an nginx service.

The nginx service is just used as a web server to serve up an `index.yaml` file. This is used in place of a real Helm repository. Using this makes demonstrating the issue quick and simple. Also it allows you to test different values quickly that may cause issues.

## Running

Presuming we are using Docker Compose v2, we can start using this command:

```sh
docker compose up -d
```

Nexus takes *about a minute* to initialise the first time.

An initialisation container will perform setup once Nexus is up, so the above command will hang for a few minutes waiting for initialisation to complete.

## Logging in

Use credentials: `admin` / `MyAdminPassword`

## Accessing

URL: <http://localhost:8182/>

The following Helm repositories are set up:

| URL | Description |
|-----|-------------|
| <http://localhost:8182/repository/helm-test> | Proxy to local nginx test server |


## Testing

Firstly we can demonstrate that using Helm directly against nginx works fine.

```sh
helm repo add nginx --force-update http://localhost:18185/
```

Then we demonstrate that when proxied via Nexus that we have an issue

```sh
helm repo add nexus --force-update http://localhost:8182/repository/helm-test/
```

You can also check the `index.yaml` files directly for each to compare:

* <http://localhost:18185/index.yaml>
* <http://localhost:8182/repository/helm-test/index.yaml>

This shows that difference in quoting of values. Quickly check the output with curl:

```sh
curl http://localhost:18185/index.yaml
curl http://localhost:8182/repository/helm-test/index.yaml
```

> **Note:** The `--force-update` just means that any existing repo is overwritten. It is above for convenience, to allow repeated tests.

### Updating the nginx content

You can simply edit the `index.yaml` file in the project without restarting nginx. Edit the `appVersion` attribute to remote the `_`.

Since Nexus has cached the proxied repository content, you will need to invalidate the cache first. Then perform a `helm repo add` again, and it should succeed this time.

### Invalidating the cache

To invalidate the cache for `helm-test`, use this command:

```sh
curl -v -X POST -u admin:MyAdminPassword -H "accept: application/json" http://localhost:8182/service/rest/v1/repositories/helm-test/invalidate-cache
```
