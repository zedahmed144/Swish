FROM --platform=linux/amd64 jenkins/jenkins:latest
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY --chown=jenkins:jenkins configs/ configs/
COPY --chown=jenkins:jenkins initial-setup.sh /bin/
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false" 
USER root
ENTRYPOINT [ "/usr/bin/tini", "--", "/bin/initial-setup.sh"]