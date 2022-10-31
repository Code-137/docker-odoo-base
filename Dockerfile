FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
ENV TERM=xterm
# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

	##### Dependências #####

ADD conf/apt-requirements /opt/sources/
ADD conf/pip-requirements /opt/sources/

WORKDIR /opt/sources/
RUN apt-get update && apt-get install -y --no-install-recommends $(grep -v '^#' apt-requirements)

RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    curl -L https://www.npmjs.com/install.sh | sh && \
    npm install -g less && npm cache clean --force

ENV LC_ALL pt_BR.UTF-8

ADD conf/brasil-requirements /opt/sources/
RUN pip3 install setuptools && pip3 install --no-cache-dir --upgrade pip
RUN pip3 install --no-cache-dir -r pip-requirements && \
    pip3 install --no-cache-dir -r brasil-requirements

# Postgres latest version
RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update && apt-get install -y --no-install-recommends postgresql-client

	##### Repositórios TrustCode e OCB #####

WORKDIR /opt/odoo/
RUN mkdir private

	##### Configurações Odoo #####

ADD conf/supervisord.conf /etc/supervisor/supervisord.conf

RUN mkdir /var/log/odoo && \
    mkdir /opt/dados && \
    mkdir /var/log/supervisord && \
    touch /var/log/odoo/odoo.log && \
    touch /var/run/odoo.pid && \
    ln -s /opt/odoo/odoo/odoo-bin /usr/bin/odoo-server && \
    ln -s /etc/odoo/odoo.conf && \
    ln -s /var/log/odoo/odoo.log && \
    useradd --system --home /opt --shell /bin/bash --uid 1040 odoo && \
    chown -R odoo:odoo /opt && \
    chown -R odoo:odoo /var/log/odoo && \
    chown odoo:odoo /var/run/odoo.pid

	##### Limpeza da Instalação #####

RUN apt-get autoremove -y && \
    apt-get autoclean

	##### Finalização do Container #####

WORKDIR /opt/odoo

