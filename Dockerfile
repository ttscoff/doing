FROM ruby:3.0.1
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN mkdir /doing
WORKDIR /doing
COPY ./ /doing/
RUN gem install bundler:2.2.17
# RUN bundle update --bundler
RUN bundle install
CMD ["rake", "parallel:test"]
