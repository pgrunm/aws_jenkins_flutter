FROM jenkins/inbound-agent:4.6-1-alpine
# Prerequisites
# Required for Alpine Linux as it contains no curl
# Ruby stuff required for installation of Fastlane
USER root
RUN apk --no-cache add curl ruby ruby-dev g++ make openssl

# Install lcov, currently in Edge branch, testing repo
RUN apk --no-cache add lcov \
--repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing

# Required Settings for Fastlane to work
ENV LC_ALL="en_US.UTF-8"
ENV LANG="en_US.UTF-8"
# Install the Fastlane Ruby package
RUN gem install fastlane -N

# Create a new user
USER jenkins
WORKDIR /home/jenkins

# Install Android stuff
RUN mkdir -p Android/sdk/
ENV ANDROID_SDK_ROOT /home/jenkins/Android/Sdk
RUN mkdir -p .android && touch .android/repositories.cfg

# Setup Android SDK
RUN wget -q -O sdk-tools.zip \
https://dl.google.com/android/repository/commandlinetools-linux-6858069_latest.zip
RUN unzip sdk-tools.zip && rm sdk-tools.zip
RUN mv -v cmdline-tools Android/sdk/cmdline-tools/
RUN cd Android/sdk/cmdline-tools/bin && yes | \
./sdkmanager --sdk_root=$ANDROID_SDK_ROOT --licenses
RUN cd Android/sdk/cmdline-tools/bin && \
./sdkmanager --sdk_root=$ANDROID_SDK_ROOT "build-tools;29.0.3" "patcher;v4" \
"platform-tools" "platforms;android-29" "sources;android-29"

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git

# Update Path Variable with all installed tools
ENV PATH "$PATH:/home/jenkins/flutter/bin"

# Add Slyph Package for Integration Tests
RUN flutter pub global activate sylph 

ENV PATH "$PATH:/home/jenkins/.pub-cache/bin"

# Run basic checks to download Dark SDK
RUN flutter doctor
RUN fastlane actions
RUN sylph --help