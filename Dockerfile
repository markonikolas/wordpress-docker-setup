# TASK RUNNER
FROM node:16.14-slim as task-runner

ARG THEME_PATH=wp-content/themes/nst-metal

WORKDIR /var/www/html/${THEME_PATH}

COPY ${THEME_PATH}/* ./

RUN npm ci

ENTRYPOINT [ "npm", "run" ]

CMD [ "watch" ]

# APP
FROM wordpress:latest as application

RUN apt update && \
    apt install -y vim && \
    a2enmod rewrite && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf

ENV USERID=admin
ENV GROUPID=www-data
ARG ROOT_PATH=/var/www/html

RUN useradd --shell /bin/bash --no-create-home --gid ${GROUPID} ${USERID} 

USER root

COPY . ${ROOT_PATH}

COPY ./permissions.sh ${ROOT_PATH}

WORKDIR ${ROOT_PATH}

RUN chmod ug+x wait.sh permissions.sh

USER ${USERID}

ENTRYPOINT [ "docker-entrypoint.sh" ]

CMD [ "apache2-foreground", "--", "./permissions.sh" ]

# DB
FROM mysql:8.0 as database

ARG DUMP=wordpress.sql.zip

WORKDIR /docker-entrypoint-initdb.d

COPY ${DUMP} .

RUN apt update && \
    apt install unzip -y && \
    unzip -o ${DUMP} && \
    rm -f ${DUMP}

ENTRYPOINT [ "docker-entrypoint.sh" ]

CMD [ "mysqld", "--authentication-policy=mysql_native_password", "--character-set-server=utf8mb4", "--collation-server=utf8mb4_general_ci" ]