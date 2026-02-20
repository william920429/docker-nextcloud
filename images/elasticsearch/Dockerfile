ARG ELASTIC_VERSION=9.3.0

FROM elasticsearch:${ELASTIC_VERSION}

ARG ELASTIC_VERSION
RUN elasticsearch-plugin install --batch \
    https://get.infini.cloud/elasticsearch/analysis-ik/${ELASTIC_VERSION} \
    https://get.infini.cloud/elasticsearch/analysis-stconvert/${ELASTIC_VERSION}
