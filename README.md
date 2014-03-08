elasticmetric
=============

Send System Metrics to ElasticSearch. 

Plugins from the directory plugins are loaded and run each in its own thread.

Sending the Metrics is done by a ow thread. I case the metrics can not be submittet the metrics are queued and sent later.
