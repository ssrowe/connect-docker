FROM eclipse-temurin:17.0.6_10-jre

RUN apt-get clean && apt-get update && apt-get install -y --no-install-recommends locales \
unzip \ 
&& sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen

# Pass in Mirth install file to build...
#   docker build . --build-arg ARTIFACT=https://s3.amazonaws.com/downloads.mirthcorp.com/connect/4.2.0.b2825/mirthconnect-4.2.0.b2825-unix.tar.gz
ARG ARTIFACT

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN curl -SL $ARTIFACT \
    | tar -xzC /opt \
    && mv "/opt/Mirth Connect" /opt/connect

RUN useradd -u 1000 mirth
RUN mkdir -p /opt/connect/appdata && chown -R mirth:mirth /opt/connect/appdata

VOLUME /opt/connect/appdata
VOLUME /opt/connect/custom-extensions
WORKDIR /opt/connect
RUN rm -rf cli-lib manager-lib \
    && rm mirth-cli-launcher.jar mirth-manager-launcher.jar mccommand mcmanager
RUN (cat mcserver.vmoptions /opt/connect/docs/mcservice-java9+.vmoptions ; echo "") > mcserver_base.vmoptions
EXPOSE 8443

COPY ./aws/* /opt/connect/server-lib/aws
RUN chmod 755 /opt/connect/server-lib/aws/*.jar

COPY entrypoint.sh /
RUN chmod 755 /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

RUN chown -R mirth:mirth /opt/connect
USER mirth
CMD ["./mcserver"]