#!groovy

import jenkins.model.*
import hudson.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

// Create a local user accounts
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('JENKINS_ADMIN_USER','JENKINS_ADMIN_PASS')
hudsonRealm.createAccount('JENKINS_BUILD_USER','JENKINS_BUILD_PASS')
hudsonRealm.createAccount('JENKINS_READ_USER','JENKINS_READ_PASS')
instance.setSecurityRealm(hudsonRealm)

// Setup permissions
// See https://gist.github.com/jnbnyc/c6213d3d12c8f848a385
def strategy = new GlobalMatrixAuthorizationStrategy()
strategy.add(Jenkins.READ, "JENKINS_BUILD_USER")
strategy.add(hudson.model.Item.READ, "JENKINS_BUILD_USER")
strategy.add(hudson.model.Item.BUILD, "JENKINS_BUILD_USER")
strategy.add(hudson.model.Item.CANCEL, "JENKINS_BUILD_USER")
strategy.add(Jenkins.READ, "JENKINS_READ_USER")
strategy.add(hudson.model.Item.READ, "JENKINS_READ_USER")


// Setting Admin Permissions
strategy.add(Jenkins.ADMINISTER, "JENKINS_ADMIN_USER")

instance.setAuthorizationStrategy(strategy)
instance.save()