// Creates a job which, when run, will recreate the Jenkins job configurations from a Bitbucket repository
// which has the backed up Jenkins job configuration XML files stored.

pipelineJob("Restore Jobs from Bitbucket") {
  definition {
    cps {
      script("""\
                import jenkins.model.Jenkins;
                
                node("master") {
                    String restoredJobsDir = pwd(tmp: true) + "/jobs"
                    String jobsDir = "\$JENKINS_HOME/jobs"
                    // We will use an official Git supported approach to resolving credentials where an inline Bash script is executed
                    // upon performing Git operations that require credentials. Our implementation requires that the BITBUCKET_USERNAME
                    // and BITBUCKET_PASSWORD environment variables have been set when executing a Git command so they can be digested
                    // and returned to Git via this inline Bash script.
                    String credentialHelper = '!f() { echo ""username=\$BITBUCKET_USERNAME""; echo ""password=\$BITBUCKET_PASSWORD""; }; f'
                
                    withCredentials([usernamePassword(credentialsId: 'gomoney_bitbucket', usernameVariable: 'BITBUCKET_USERNAME', passwordVariable: 'BITBUCKET_PASSWORD')]) {
                        sh \"\"\"
                            rm -rf "\$restoredJobsDir"
                            mkdir "\$restoredJobsDir"
                            bash -c 'cd "\$restoredJobsDir"; git init'
                            bash -c 'cd "\$restoredJobsDir"; git remote add origin $jobsBackupRepository'
                            bash -c 'cd "\$restoredJobsDir"; git config credential.helper "\$credentialHelper"'
                            # Important: We need to set the GIT_COMMITTER_NAME and GIT_COMMITTER_EMAIL environment variables otherwise the version
                            # of Git on the Jenkins OS image will fail due to missing user data in /etc/passwd. More recent versions of Git
                            # apparently do not have this limitation and instead of the environment variables, having a user and email in the
                            # .git/config file would be sufficient. Note that performing a Git clone with embedded credentials in the URL does
                            # not experience this issue however this is unsafe as the url and the embedded credentials are saved in plain text
                            # to the .git/config file. This particular job does not push any code (only pull) so the actual values for the Git
                            # committer fields are not important as no commits are made.
                            bash -c 'cd "\$restoredJobsDir"; GIT_COMMITTER_NAME=jenkins GIT_COMMITTER_EMAIL=email git pull origin $jobsBackupRepositoryBranch'
                            
                            rsync --archive --verbose "\$restoredJobsDir/" "\$jobsDir"
                        \"\"\"
                    }
                    
                    Jenkins.instance.doReload()
                }
            """.stripIndent())

      sandbox(true)
    }
  }
}