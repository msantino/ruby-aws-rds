FROM ruby:2.4.1-onbuild

COPY . /usr/src/app

CMD ["ruby", "/usr/src/app/download_instance_logs.rb"]
