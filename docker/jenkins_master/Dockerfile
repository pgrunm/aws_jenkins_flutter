FROM jenkins/jenkins:2.263.1-lts

# Install the Jenkins Plugins from the plugins text file
# like described in the docs:
# https://github.com/jenkinsci/docker#plugin-installation-manager-cli-preview
COPY code/docker/Test/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Copy the groovy config file
COPY code/docker/Test/initialConfig.groovy /usr/share/jenkins/ref/init.groovy.d/initialConfigs.groovy
COPY code/docker/Test/jenkins.yaml /usr/share/jenkins/ref/jenkins.yaml

# Create the app pipeline from config files
COPY code/docker/Test/helloWorld.xml /usr/share/jenkins/ref/jobs/Hello-World/config.xml
COPY code/docker/Test/appConfig.xml /usr/share/jenkins/ref/jobs/Flutter-App/config.xml

ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false