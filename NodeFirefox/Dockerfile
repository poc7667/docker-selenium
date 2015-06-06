FROM selenium/node-base:2.45.0
MAINTAINER Selenium <selenium-developers@googlegroups.com>
USER root

#=========
# Firefox
#=========
RUN apt-get update -qqy \
    && apt-get -qqy --no-install-recommends install \
    firefox \
    && rm -rf /var/lib/apt/lists/*

#========================
# Selenium Configuration
#========================
COPY config.json /opt/selenium/config.json

RUN apt-get update && apt-get -y upgrade && apt-get -y -qq --force-yes install \
    build-essential \
    tree \
    ruby-dev \
    vim \
    vim-scripts \
    git \
    git-flow\
    curl \
    zsh \
    build-essential \
    openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev \ 
    libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev \
    autoconf libc6-dev ncurses-dev automake libtool bison nodejs  \
    libpq-dev imagemagick
# Install Zsh
################## BEGIN INSTALLATION ######################
RUN git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh \
    && cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc \
    && chsh -s /bin/zsh

RUN sed -i -E "s/^plugins=\((.*)\)$/plugins=(\1 git git-flow ruby )/" ~/.zshrc  
RUN echo "export TERM=vt100" >> /etc/zsh/zshrc

# bindkey to make HOME/END works on zsh shell
# set term=xtern make HOME/END works in vim
RUN echo "alias ls='ls --color=auto'" >> /etc/zsh/zshrc && \
    echo "alias ll='ls -halF'" >> /etc/zsh/zshrc && \
    echo "bindkey -v" >> /etc/zsh/zshrc && \
    echo "bindkey '\eOH'  beginning-of-line" >> /etc/zsh/zshrc && \
    echo "bindkey '\eOF'  end-of-line" >> /etc/zsh/zshrc && \
    echo "alias ls='ls --color=auto'" >> /etc/profile &&\
    echo "set term=xterm" >> ~/.vimrc 

# Install vim plugins
WORKDIR /tmp
COPY Gemfile Gemfile
RUN gem install bundler
RUN bundle install

#====================================
# Scripts to run cron job
#====================================
# ADD cron_lazy_bird /etc/crontab
# RUN touch /var/log/cron.log
# RUN crontab /etc/crontab
