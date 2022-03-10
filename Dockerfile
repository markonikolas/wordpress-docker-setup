ARG WORDPRESS_VERSION=latest
ARG MYSQL_VERSION=latest
ARG NODE_VERSION=latest

FROM node:$NODE_VERSION as task-runner

ENV GREEN='\033[1;32m' PURPLE='\033[0;35m' NC='\033[0m'

ARG MODE=development THEME_PATH=wp-content/themes/twentytwentyone

RUN if [ "$MODE" = "verbose" ] ; then \
    echo "\n${GREEN}NODE_VERSION:${NC} ${NODE_VERSION} \n${GREEN}THEME_PATH:${NC} ${THEME_PATH}\n"; fi

WORKDIR /var/www/html/${THEME_PATH}

COPY ${THEME_PATH}/* ./

RUN npm ci

ENTRYPOINT [ "npm", "run" ]

CMD [ "watch" ]

# APP
FROM wordpress:$WORDPRESS_VERSION as application

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

CMD [ "apache2-foreground" ]

# DB
FROM mysql:$MYSQL_VERSION as database

ARG DUMP=wordpress.sql.zip

WORKDIR /docker-entrypoint-initdb.d

COPY ${DUMP} .

RUN apt update && \
    apt install unzip -y && \
    unzip -o ${DUMP} && \
    rm -f ${DUMP}

ENTRYPOINT [ "docker-entrypoint.sh" ]

CMD [ "mysqld", "--authentication-policy=mysql_native_password", "--character-set-server=utf8mb4", "--collation-server=utf8mb4_general_ci" ]