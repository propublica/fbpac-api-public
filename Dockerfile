FROM ruby:2.3

RUN apt-get update

# application dependencies
RUN apt-get install -y libmysqlclient-dev libpq-dev libcurl4-openssl-dev
RUN apt-get install -y nodejs
RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc

WORKDIR /web/
ADD Gemfile /web/
ADD Gemfile.lock /web/
ADD ./vendor/cache /web/vendor/cache
RUN bundle install --deployment --without development --jobs=2

ADD . /web/

ENV RAILS_ENV production

RUN bundle exec rake assets:clobber assets:precompile assets:gzip assets:sync

EXPOSE 115
CMD bundle exec unicorn -c ./config/unicorn.conf.rb
