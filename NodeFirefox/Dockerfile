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

# Make ssh dir
RUN mkdir /root/.ssh/
# Copy over private key, and set permissions
# ADD id_rsa /root/.ssh/id_rsa
# Create known_hosts
RUN touch /root/.ssh/known_hosts
# Add bitbuckets key
RUN ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts
# Install vim plugins
RUN mkdir -p ~/.vim/bundle                                          && \
    cd  ~/.vim/bundle                                                   && \
    git clone --depth 1 https://github.com/gmarik/Vundle.vim.git        && \
    git clone --depth 1 https://github.com/majutsushi/tagbar.git        && \
    git clone --depth 1 https://github.com/Shougo/neocomplete.vim.git   && \
    git clone --depth 1 https://github.com/scrooloose/nerdtree.git      && \
    git clone --depth 1 https://github.com/bling/vim-airline.git        && \
    git clone --depth 1 https://github.com/tpope/vim-fugitive.git       && \
    git clone --depth 1 https://github.com/jistr/vim-nerdtree-tabs.git  && \
    git clone --depth 1 https://github.com/mbbill/undotree.git          && \
    git clone --depth 1 https://github.com/Lokaltog/vim-easymotion.git  && \
    git clone --depth 1 https://github.com/scrooloose/nerdcommenter.git && \
    vim +PluginInstall +qall

WORKDIR /tmp
COPY install_vundles.sh install_vundles.sh
RUN bash install_vundles.sh
WORKDIR /tmp
COPY Gemfile Gemfile
RUN gem install bundler
RUN bundle install

#====================================
# Scripts to run cron job
#====================================

# Add crontab file in the cron directory
ADD cron_lazy_bird /etc/crontab
# Create the log file to be able to run tail
RUN touch /var/log/cron.log
# Use the crontab file
RUN crontab /etc/crontab
# Run the command on container startup
#CMD cron  && tail -f /var/log/cron.log
