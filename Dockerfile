FROM ruby
MAINTAINER Marc Dougherty <muncus@gmail.com>

COPY Gemfile /app/Gemfile
WORKDIR /app
RUN bundle install
RUN bundle update
COPY . /app
EXPOSE 8080
ENTRYPOINT ["bundle", "exec", "jekyll"]
CMD ["serve", "-D", "--unpublished", "--future",  "--port", "8080", "--host", "0.0.0.0"]
