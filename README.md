#CF Cassandra Broker

CF Cassandra Broker provides Cassandra databases as a Cloud Foundry service. 
For more info see [http://docs.cloudfoundry.com/docs/running/architecture/services/].

The broker does not include a Cassandra server or a cluster. Instead, it is meant to be deployed alongside a Cassandra server or a cluster, which it manages.  These are the Cassandra management tasks that the broker performs.

* Provisioning of database instances (create)
* Creation of credentials (bind)
* Removal of credentials (unbind)
* Unprovisioning of database instances (delete)

## Running Tests

The CF Cassandra Broker integration specs will exercise the catalog fetch, create, bind, unbind, and delete functions against its specified Cassandra database.

1. Run a local Cassandra cluster(Maybe managed by BOSH).

2. Run the following commands

```
$ cd cf-cassandra-broker
$ bundle
$ bundle exec rake db:setup
$ bundle exec rake spec
```
