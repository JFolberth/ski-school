FROM nginxinc/nginx-unprivileged:stable-alpine@sha256:f5116ed4606f3eb015dd4a8e28cb9b351476dc0ad4bc6e9f93b19cec130cdf03

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html styles.css app.js /usr/share/nginx/html/
COPY deployment-metadata.sh /docker-entrypoint.d/40-deployment-metadata.sh

USER 0:0
RUN chmod 755 /docker-entrypoint.d/40-deployment-metadata.sh
USER 101:101
EXPOSE 8080
