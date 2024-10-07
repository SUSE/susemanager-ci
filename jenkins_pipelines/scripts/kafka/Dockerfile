FROM apache/kafka:3.7.1

USER root

RUN \
  apk \
    update \
  && \
  apk \
    add \
      git=2.43.5-r0 \
      python3=3.11.10-r0 \
      python3-dev=3.11.10-r0 \
      py3-pip=23.3.1-r0 \
      gcc=13.2.1_git20231014-r0 \
      g++=13.2.1_git20231014-r0 \
      librdkafka-dev=2.3.0-r1

USER appuser

COPY --chown=appuser "consumer.py" "producer.py" "/home/appuser/"

WORKDIR "/home/appuser"

RUN \
  python3 \
    -m \
      venv \
      "/home/appuser/venv" \
  && \
  . \
    "/home/appuser/venv/bin/activate" \
  && \
  pip \
    install \
      confluent_kafka==2.3.0 \
      GitPython==3.1.43 \
      requests==2.32.3 \
  && \
  git \
    clone \
      "https://github.com/SUSE/susemanager-ci"

ENTRYPOINT ["/bin/bash", "-c", \
  "/etc/kafka/docker/run & \
  /opt/kafka/bin/kafka-topics.sh \
    --create \
    --if-not-exists \
    --topic sle_mu_43 \
    --bootstrap-server localhost:9092 \
  && \
  . \
    /home/appuser/venv/bin/activate \
  && \
  python3 \
     consumer.py" \
]

