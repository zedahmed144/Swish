#!/bin/sh
DESTINATION_DIR=/var/jenkins_home
cp -r configs/. ${DESTINATION_DIR}
# Insert dynamic value in the config

sed -i "s,GITHUB_USER,${GITHUB_USER},g; \
        s,GITHUB_PASS,${GITHUB_PASS},g;" \
    ${DESTINATION_DIR}/credentials.xml

sed -i "s,GITHUB_REPO,${GITHUB_REPO},g; \
        s,GITHUB_BRANCH,${GITHUB_BRANCH},g;" \
    ${DESTINATION_DIR}/jobs/Morningstarconfig.xml    
sed -i "s,JENKINS_BUILD_USER,${JENKINS_BUILD_USER},g; \
        s,JENKINS_BUILD_PASS,${JENKINS_BUILD_PASS},g; \
        s,JENKINS_ADMIN_USER,${JENKINS_ADMIN_USER},g; \
        s,JENKINS_ADMIN_PASS,${JENKINS_ADMIN_PASS},g; \
        s,JENKINS_READ_USER,${JENKINS_READ_USER},g; \
        s,JENKINS_READ_PASS,${JENKINS_READ_PASS},g;" \
    ${DESTINATION_DIR}/init.groovy.d/user-setup.groovy

# Run jenkins
/usr/local/bin/jenkins.sh   
