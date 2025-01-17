FROM registry.artifakt.io/magento:2.4-apache

ARG CODE_ROOT=.

COPY --chown=www-data:www-data $CODE_ROOT /var/www/html/

WORKDIR /var/www/html

USER www-data
RUN [ -f composer.lock ] && composer install --no-cache --no-interaction --no-ansi --no-dev || true
RUN php bin/magento setup:di:compile
RUN composer dump-autoload --no-dev --optimize --apcu
RUN php bin/magento setup:static-content:deploy -f --no-interaction --jobs 5
USER root

# copy the artifakt folder on root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN  if [ -d .artifakt ]; then cp -rp /var/www/html/.artifakt/ /.artifakt/; fi

# run custom scripts build.sh
# hadolint ignore=SC1091
RUN --mount=source=artifakt-custom-build-args,target=/tmp/build-args \
  if [ -f /tmp/build-args ]; then source /tmp/build-args; fi && \
  if [ -f /.artifakt/build.sh ]; then /.artifakt/build.sh; fi
