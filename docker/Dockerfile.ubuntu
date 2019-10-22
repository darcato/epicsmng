FROM ubuntu:latest

# Add the epicsmng executable location to PATH
ENV HOME="${HOME:-/root}"
ENV PATH="${HOME:-/root}/.local/bin:${PATH}"

# Install required packets to build code
RUN apt-get update \ 
    && apt-get -y install \
        git \
        build-essential \
        libreadline-dev \
        wget \
        libc-dev-bin \
        re2c

# Copy epicsmng code from repository
COPY . /epicsmng

# Install, clean source files and set the github mirror of the base to be used (faster)
RUN sh /epicsmng/install.sh \
    && rm -rf /epicsmng \
    && echo "" >> $HOME/.config/epicsmng/settings/user.settings \
    && echo "base_url=\"https://github.com/epics-base/epics-base\"" >> $HOME/.config/epicsmng/settings/user.settings
