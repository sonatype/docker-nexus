/*
 * Copyright (c) 2016-present Sonatype, Inc. All rights reserved.
 * Includes the third-party code listed at http://links.sonatype.com/products/nexus/attributions.
 * "Sonatype" is a trademark of Sonatype, Inc.
 */
@Library(['private-pipeline-library', 'jenkins-shared']) _
import com.sonatype.jenkins.pipeline.GitHub
import com.sonatype.jenkins.pipeline.OsTools

properties([
  parameters([
    string(defaultValue: '', description: 'New Nexus Repository Manager Version', name: 'nexus_repository_manager_version')
  ])
])

node('ubuntu-zion') {
  def commitId, commitDate, longVersion, imageId, branch, dockerImages
  def organization = 'sonatype',
      gitHubRepository = 'docker-nexus',
      credentialsId = 'integrations-github-api',
      imageName = 'sonatype/nexus',
      archiveName = 'docker-nexus',
      dockerHubRepository = 'nexus'
  GitHub gitHub

  try {
    stage('Preparation') {
      deleteDir()
      OsTools.runSafe(this, "docker system prune -a -f")

      def checkoutDetails = checkout scm

      dockerImages = [
        [ dockerFilePath: "${pwd()}/oss/Dockerfile", imageTag: "${imageName}:oss", imageId: "", flavor: "oss" ],
        [ dockerFilePath: "${pwd()}/pro/Dockerfile", imageTag: "${imageName}:pro", imageId: "", flavor: "pro" ]
      ]

      branch = checkoutDetails.GIT_BRANCH == 'origin/main' ? 'main' : checkoutDetails.GIT_BRANCH
      commitId = checkoutDetails.GIT_COMMIT

      OsTools.runSafe(this, 'git config --global user.email sonatype-ci@sonatype.com')
      OsTools.runSafe(this, 'git config --global user.name Sonatype CI')

      longVersion = readLongVersion()

      withGitHubAppToken {
        gitHub = new GitHub(this, "${organization}/${gitHubRepository}", "${GITHUB_TOKEN}")
      }
    }
    if (params.nexus_repository_manager_version) {
      stage('Update Repository Manager Version') {
        OsTools.runSafe(this, "git checkout ${branch}")
        dockerImages.each { updateRepositoryManagerVersion(it.dockerFilePath) }
        longVersion = params.nexus_repository_manager_version
      }
    }
    stage('Build') {
      gitHub.statusUpdate commitId, 'pending', 'build', 'Build is running'
      dockerImages.each { image ->
        def hash = OsTools.runSafe(this, "docker build --quiet --no-cache --tag ${image.imageTag} -f ${image.dockerFilePath} .")
        image.imageId = hash.split(':')[1]

        if (currentBuild.result == 'FAILURE') {
            gitHub.statusUpdate commitId, 'failure', 'build', 'Build failed'
            return
        } else {
            gitHub.statusUpdate commitId, 'success', 'build', 'Build succeeded'
        }
      }
    }
    if (params.nexus_repository_manager_version) {
      stage('Commit Repository Manager Version Update') {
        def commitMessage = "Update Repository Manager to ${params.nexus_repository_manager_version}."
        sonatypeZionGitConfig()
        sshagent(credentials: [sonatypeZionCredentialsId()]) {
          sh """git add .
                git commit -m '${commitMessage}'
                git push origin ${branch}
                """
        }
      }
    }
    stage('Archive') {
      dir('build/target') {
        dockerImages.each {
            OsTools.runSafe(this, "docker save ${it.imageId} | gzip > ${archiveName}-${it.flavor}.tar.gz")
        }
        archiveArtifacts artifacts: "${archiveName}-*.tar.gz", onlyIfSuccessful: true
      }
    }
    if (branch != 'main') {
      return
    }
    input 'Push image and tags?'
    stage('Push image and tags') {
      withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'docker-hub-credentials',
            usernameVariable: 'DOCKERHUB_API_USERNAME', passwordVariable: 'DOCKERHUB_API_PASSWORD']]) {
        dockerImages.each { image ->
            def tags = getTags(image.flavor, longVersion)
            tags.each { tag ->
                OsTools.runSafe(this, "docker tag ${image.imageId} ${organization}/${dockerHubRepository}:${tag}")
            }
        }
        OsTools.runSafe(this, """
            docker login --username ${env.DOCKERHUB_API_USERNAME} --password ${env.DOCKERHUB_API_PASSWORD}
            """)
        OsTools.runSafe(this, "docker push --all-tags ${organization}/${dockerHubRepository}")
      }
    }
    stage('Push tags') {
      def shortVersion = getShortVersion(longVersion)
      sonatypeZionGitConfig()
      sshagent(credentials: [sonatypeZionCredentialsId()]) {
        sh """git tag ${shortVersion}
              git push origin ${shortVersion}
              """
      }
      OsTools.runSafe(this, "git tag -d ${shortVersion}")
    }
  } finally {
    OsTools.runSafe(this, "docker logout")
    OsTools.runSafe(this, "docker system prune -a -f")
    OsTools.runSafe(this, 'git clean -f && git reset --hard origin/main')
  }
}

def readLongVersion() {
  def content = readFile 'oss/Dockerfile'
  for (line in content.split('\n')) {
    if (line.startsWith('ARG NEXUS_VERSION=')) {
      return line.substring(18)
    }
  }
  error 'Could not determine version.'
}

def getShortVersion(longVersion) {
  return longVersion.split('-')[0]
}

def getTags(flavor, longVersion) {
    def shortVersion = getShortVersion(longVersion)
    if (flavor == "pro") {
        return ["pro", "pro-${shortVersion}", "pro-${longVersion}"]
    }
    else {
        return ["oss", "${shortVersion}", "${longVersion}", "latest"]
    }
}

def updateRepositoryManagerVersion(dockerFileLocation) {
  def dockerFile = readFile(file: dockerFileLocation)

  def versionRegex = /(ARG NEXUS_VERSION=)(\d\.\d{1,3}\.\d{1,3}\-\d{2})/

  dockerFile = dockerFile.replaceAll(versionRegex, "\$1${params.nexus_repository_manager_version}")

  writeFile(file: dockerFileLocation, text: dockerFile)
}
