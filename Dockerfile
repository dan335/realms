FROM ruby:slim

RUN echo "Etc/UTC" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

RUN apt-get update && apt-get install -y build-essential libsodium 

RUN mkdir /app
WORKDIR /app

ADD Gemfile Gemfile.lock /app/
RUN bundle install -j 8

ADD . /app

CMD ["ruby", "app.rb"]
