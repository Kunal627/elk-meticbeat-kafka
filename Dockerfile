# Pull kafka image
FROM lensesio/fast-data-dev:latest
LABEL maintainer="kc1234@gmail.com"
RUN curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-oss-7.8.0-linux-x86_64.tar.gz
RUN tar xvzf metricbeat-oss-7.8.0-linux-x86_64.tar.gz
COPY metricbeat.yml /metricbeat-7.8.0-linux-x86_64
COPY kafka.yml /metricbeat-7.8.0-linux-x86_64/modules.d
COPY jolokia.yml /metricbeat-7.8.0-linux-x86_64/modules.d
RUN curl -L -O https://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-jvm/1.6.2/jolokia-jvm-1.6.2-agent.jar
