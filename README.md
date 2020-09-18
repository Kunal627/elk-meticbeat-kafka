# elk-meticbeat-kafka
Steps to setup metricbeat for monitoring Kafka with Docker files and config

# Objective
The objective is to setup a quick POC for monitoring Kafka using metricbeat and jolokia.

This document describes steps

- To setup out of the box Kibana dashboards for Kafka (Manual)
- List of Kafka metrics to observe
- Docker setup for the POC (Setup using Docker compose)

# Software Prerequisites

This POC has been done on following tech stack:

- Docker desktop community version 2.3.0.3(45519) on Windows 10
- lensesio/fast-data-dev (Kafka Version 2.2.1)
- sebp/elk image for ELK stack (ELK version 7.8.0)
- Metric Beat Plugin version 7.8.0 (partition and consumer group metrics by default)
- Jolokia version 1.6.2 (for broker, consumer and producer metrics)

# Setup

## Bring up ELK and Kafka containers.

1. Create a bridge adapter so that ELK and Kafka containers are on same network

docker network create -d bridge elknet

1. docker run -p 5601:5601 -p 9200:9200 -p 5044:5044 -it --name elk --network=elknet sebp/elk
2. docker run --rm -p 2181:2181 -p 3030:3030 -p 8081-8083:8081-8083 -p 9581-9585:9581-9585 -p 9092:9092 -p 80:80 -e ADV\_HOST=localhost -it --network=elknet lensesio/fast-data-dev:latest

## Test Kafka and Kibana

1. [http://localhost:3030/](http://localhost:3030/) should be up and running Kafka UI
2. [http://localhost:5601/](http://localhost:5601/) should be up and running Kibana

## Metricbeat Setup

Install Metric Beat on Kafka container

1. curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-oss-7.9.0-linux-x86\_64.tar.gz
2. tar xvzf metricbeat-7.8.0-linux-x86\_64.tar.gz
3. ./metricbeat modules enable kafka
4. ./metricbeat modules enable jolokia
5. curl -L -O [https://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-jvm/1.6.2/jolokia-jvm-1.6.2-agent.jar](https://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-jvm/1.6.2/jolokia-jvm-1.6.2-agent.jar) in /opt directory
6. Please refer yml config files in Appendix
7. Restart Kafka container after setting up all config files (kafka.yml, metricbeat.yml and jolokia.yml)
8. Test jolokia is running and listening on port 8778

sudo netstat -ltnp

curl -s http://localhost:8778/jolokia/version | jq

1. Run command export KAFKA\_OPTS=-javaagent:/opt/jolokia-jvm-1.6.2-agent.jar=port=8775,host=localhost
2. Start the console producer
3. Run command export KAFKA\_OPTS=-javaagent:/opt/jolokia-jvm-1.6.2-agent.jar=port=8774,host=localhost
4. Start the console consumer
5. Enter messages into console producer, the messages will be displayed on console consumer
6. Login to Kibana UI and search for MetricBeat Kafka dashboard.

![](RackMultipart20200917-4-q15lq0_html_470b866298881179.png)

# Kafka Metrics

## Out of the box visualizations:

1. Kafka Topic and Consumer Offset

It is an integer number which maintains the current position of topic and consumer for a topic.

1. Consumer Group Lag by Topic

This metric represents how far the consumer group application is behind the producers. Lag should be close to zero or at least somewhat flat and stable, which would mean the application is keeping up with the producers.

1. Total number of topics, brokers, partitions and replicas in the Kafka cluster.

1. Total consumer groups – Integer value represents total consumer groups active.

1. Kafka topic details like brokers, number of partitions, replicas , consumer and current position of consumer offset.

1. Consumer Partition Reassignments

## Custom Kibana Visualizations: (These are not there in out of the box vizualizations)

1. Under replicated Partitions:

To ensure data durability and that brokers are always available to deliver data, you can set a replication number per topic as applicable. As a result, data will be replicated across more than one broker, available for processing even if a single broker fails. This metric alerts you to cases where there are fewer than the minimum number of active brokers for a given topic. As a rule, there should be no under-replicated partitions in a running Kafka deployment (meaning this value should always be zero), making this a very important metric to monitor and alert on.

Use kafka.partition.partition.insync\_replica to identify in-sync replica.

1. Producer record error rate:

It represents average per second number of record sends that resulted in errors for a topic. Use kafka.producer.record\_error\_rate property for this metric.

1. Total Broker Partitions:

Knowing how many partitions a broker is managing can help you avoid errors and know when it&#39;s time to scale out. The goal should be to keep the count balanced across brokers.

1. Rejected bytes per second:

Rejected byte rate per topic. Use property kafka.broker.topic.net.rejected.bytes\_per\_sec.

1. Consumer fetch rate

The fetch rate of a consumer can be a good indicator of overall consumer health. A minimum fetch rate approaching a value of zero could potentially signal an issue on the consumer. In a healthy consumer, the minimum fetch rate will usually be non-zero, so if you see this value dropping, it could be a sign of consumer failure. Use fetch\_rate from kafka.consumer.

# Appendix

## Metric Beat config files

1. metribeat.yml


1. kafka.yml


1. jolokia.yml


## Kafka Shell script change

Add following to the very beginning of export statements in kafka-server-start.sh:

export KAFKA\_JMX\_OPTS=&quot;

-javaagent:/opt/jolokia-jvm-1.6.2-agent.jar=port=8778,host=localhost \

-Dcom.sun.management.jmxremote=true \

-Dcom.sun.management.jmxremote.authenticate=false \

-Dcom.sun.management.jmxremote.ssl=false \

-Djava.rmi.server.hostname=localhost \

-Dcom.sun.management.jmxremote.host=localhost \

-Dcom.sun.management.jmxremote.port=9999 \

-Dcom.sun.management.jmxremote.rmi.port=9999 \

-Djava.net.preferIPv4Stack=true&quot;

# Docker compose setup (In case you don't want to set it up using steps mentioned above)

This section lists the steps for setting up both elk and kafka using docker compose. The Kafka container needs to be restarted after making change to the kafka-server-start script (step 4 and 5). Steps 6 and 7 are for running console consumer and console producer. These are optional steps. Metric beat will not capture consumer and producer metrics if steps 6 and 7 are not run. And the KAFKA\_OPTS need to be set up to run jolokia to capture metrics.

Follow the steps for setting up the environment using docker compose.

1. Copy all the files (metribeat.yml, kafka.yml, jolokia.yml, Dockerfile, docker-compose.yml in a directory

2. docker-compose build

3. docker-compose up

4. Login to kafka container

====================================================

add following lines in /opt/landoop/kafka/bin/kafka-server-start (very beginning of export statements)

=====================================================

export KAFKA\_JMX\_OPTS=&quot;

-javaagent:/jolokia-jvm-1.6.2-agent.jar=port=8778,host=localhost \

-Dcom.sun.management.jmxremote=true \

-Dcom.sun.management.jmxremote.authenticate=false \

-Dcom.sun.management.jmxremote.ssl=false \

-Djava.rmi.server.hostname=localhost \

-Dcom.sun.management.jmxremote.host=localhost \

-Dcom.sun.management.jmxremote.port=9999 \

-Dcom.sun.management.jmxremote.rmi.port=9999 \

-Djava.net.preferIPv4Stack=true&quot;

5. Restart the kafka container from windows desktop

6. Open a new terminal in kafka conatiner and run following commands

======================

console producer

=====================

export KAFKA\_OPTS=-javaagent:/jolokia-jvm-1.6.2-agent.jar=port=8775,host=localhost

kafka-console-producer --broker-list localhost:9092 --topic testtopic1

7. Open a new terminal in kafka conatiner and run following commands

====================

console consumer

====================

export KAFKA\_OPTS=-javaagent:/jolokia-jvm-1.6.2-agent.jar=port=8774,host=localhost

kafka-console-consumer --bootstrap-server localhost:9092 --topic testtopic1 --from-beginning

8. Open one more terminal in kafka container and go to /metricbeat-7.8.0-linux-x86\_64 directory

and run

./metricbeat -e

9. logon to localhost:5601 to access kibana and navigate open metricbeat kafka dashboard
