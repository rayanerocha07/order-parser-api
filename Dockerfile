FROM ruby:3.2

WORKDIR /app

RUN apt-get update -qq && apt-get install -y build-essential

COPY Gemfile ./

RUN bundle install
COPY . .

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
