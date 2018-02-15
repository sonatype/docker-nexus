/*
 * Copyright (c) 2016-present Sonatype, Inc. All rights reserved.
 * Includes the third-party code listed at http://links.sonatype.com/products/nexus/attributions.
 * "Sonatype" is a trademark of Sonatype, Inc.
 */
@Library('zion-pipeline-library')
import com.sonatype.jenkins.pipeline.GitHub
import com.sonatype.jenkins.pipeline.OsTools

properties([
  parameters([
    string(defaultValue: '', description: 'New Nexus Repository Manager Version', name: 'nexus_repository_manager_version')
  ])
])

node('ubuntu-zion') {
  def commitId, commitDate, version, imageId, branch, dockerImages
  def organization = 'DarthHater',
      gitHubRepository = 'docker-nexus',
      credentialsId = 'integrations-github-api',
      imageName = 'darthhater/nexus',
      archiveName = 'docker-nexus',
      dockerHubRepository = 'nexus'
  GitHub gitHub

  try {
    stage('Preparation') {
      deleteDir()
      OsTools.runSafe(this, "docker system prune -a -f")

      def checkoutDetails = checkout scm

      dockerImages = [
        [ dockerFilePath: "${pwd()}/oss/Dockerfile", imageTag: "${imageName}:oss", flavor: "oss" ],
        [ dockerFilePath: "${pwd()}/pro/Dockerfile", imageTag: "${imageName}:oss", flavor: "pro" ]
      ]

      branch = checkoutDetails.GIT_BRANCH == 'origin/master' ? 'master' : checkoutDetails.GIT_BRANCH
      commitId = checkoutDetails.GIT_COMMIT
      commitDate = OsTools.runSafe(this, "git show -s --format=%cd --date=format:%Y%m%d-%H%M%S ${commitId}")

      // OsTools.runSafe(this, 'git config --global user.email sonatype-ci@sonatype.com')
      // OsTools.runSafe(this, 'git config --global user.name Sonatype CI')

      version = readVersion()

      println("Read Version")

      def apiToken
      withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: credentialsId,
                        usernameVariable: 'GITHUB_API_USERNAME', passwordVariable: 'GITHUB_API_PASSWORD']]) {
        apiToken = env.GITHUB_API_PASSWORD
      }
      // gitHub = new GitHub(this, "${organization}/${gitHubRepository}", apiToken)

      if (params.nexus_repository_manager_version) {
        stage('Update Repository Manager Version') {
          println(params.nexus_repository_manager_version)
          OsTools.runSafe(this, "git checkout ${branch}")
          dockerImages.each { updateRepositoryManagerVersion(it.dockerFilePath) }
          version = params.nexus_repository_manager_version
        }
      }
    }
    stage('Build') {
      // gitHub.statusUpdate commitId, 'pending', 'build', 'Build is running'
      dockerImages.each {
        def hash = OsTools.runSafe(this, "docker build --quiet --no-cache --tag ${it.imageTag} -f ${it.dockerFilePath} .")
        it.imageTag = hash.split(':')[1]

        if (currentBuild.result == 'FAILURE') {
            // gitHub.statusUpdate commitId, 'failure', 'build', 'Build failed'
            return
        } else {
            // gitHub.statusUpdate commitId, 'success', 'build', 'Build succeeded'
        }
      }
    }
    if (params.nexus_repository_manager_version) {
      stage('Commit Repository Manager Version Update') {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'integrations-github-api',
                        usernameVariable: 'GITHUB_API_USERNAME', passwordVariable: 'GITHUB_API_PASSWORD']]) {
        //   def commitMessage = params.nexus_repository_manager_version ? "Update Repository Manager to ${params.nexus_repository_manager_version}." : ""
        //   OsTools.runSafe(this, """
        //     git add .
        //     git commit -m '${commitMessage}'
        //     git push https://${env.GITHUB_API_USERNAME}:${env.GITHUB_API_PASSWORD}@github.com/${organization}/${gitHubRepository}.git ${branch}
        //   """)
        }
      }
    }
    stage('Archive') {
      dir('build/target') {
        OsTools.runSafe(this, "docker save ${imageName} | gzip > ${archiveName}.tar.gz")
        archiveArtifacts artifacts: "${archiveName}.tar.gz", onlyIfSuccessful: true
      }
    }
    if (branch != 'master') {
      return
    }
    input 'Push image and tags?'
    stage('Push image and tags') {
      def dockerhubApiToken
      withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'DarthHaterDockerHub',
            usernameVariable: 'DOCKERHUB_API_USERNAME', passwordVariable: 'DOCKERHUB_API_PASSWORD']]) {
        dockerImages.each {
            imageId = it.imageTag
            def tags = getTags(it.flavor, version)
            tags.each {
                OsTools.runSafe(this, "docker tag ${imageId} ${organization}/${dockerHubRepository}:${it}")
            }
        }
        OsTools.runSafe(this, """
            docker login --username ${env.DOCKERHUB_API_USERNAME} --password ${env.DOCKERHUB_API_PASSWORD}
            """)
        OsTools.runSafe(this, "docker push ${organization}/${dockerHubRepository}")
        
        response = OsTools.runSafe(this, """
          curl -X POST https://hub.docker.com/v2/users/login/ \
            -H 'cache-control: no-cache' -H 'content-type: application/json' \
            -d '{ "username": "${env.DOCKERHUB_API_USERNAME}", "password": "${env.DOCKERHUB_API_PASSWORD}" }'
        """)
        token = readJSON text: response
        dockerhubApiToken = token.token

        def readme = readFile file: 'README.md', encoding: 'UTF-8'
        readme = readme.replaceAll("(?s)<!--.*?-->", "")
        readme = readme.replace("\"", "\\\"")
        readme = readme.replace("\n", "\\n")
        response = httpRequest customHeaders: [[name: 'authorization', value: "JWT ${dockerhubApiToken}"]],
            acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'PATCH',
            requestBody: "{ \"full_description\": \"${readme}\" }",
            url: "https://hub.docker.com/v2/repositories/${organization}/${dockerHubRepository}/"
      }
    }
    stage('Push tags') {
      withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: credentialsId,
                        usernameVariable: 'GITHUB_API_USERNAME', passwordVariable: 'GITHUB_API_PASSWORD']]) {
        // OsTools.runSafe(this, "git tag ${version}")
        // OsTools.runSafe(this, """
        //   git push \
        //   https://${env.GITHUB_API_USERNAME}:${env.GITHUB_API_PASSWORD}@github.com/${organization}/${gitHubRepository}.git \
        //     ${version}
        // """)
      }
      // OsTools.runSafe(this, "git tag -d ${version}")
    }
  } finally {
    OsTools.runSafe(this, "docker logout")
    OsTools.runSafe(this, "docker system prune -a -f")
    OsTools.runSafe(this, 'git clean -f && git reset --hard origin/master')
  }
}

def readVersion() {
  def content = readFile 'oss/Dockerfile'
  for (line in content.split('\n')) {
    if (line.startsWith('ARG NEXUS_VERSION=')) {
      return line.substring(18).split('-')[0]
    }
  }
  error 'Could not determine version.'
}

def getTags(flavor, longVersion) {
    def shortVersion = longVersion.split('-')[0]
    if (flavor == "pro") {
        return ["pro", "pro-${shortVersion}", "pro-${longVersion}"]
    }
    else {
        return ["oss", "${shortVersion}", "${longVersion}", "latest"]
    }
}

def updateRepositoryManagerVersion(dockerFileLocation) {
  def dockerFile = readFile(file: dockerFileLocation)

  def versionRegex = /(ARG NEXUS_VERSION=)(\d\.\d{1,3}\.\d\-\d{2})/

  dockerFile = dockerFile.replaceAll(versionRegex, "\$1${params.nexus_repository_manager_version}")

  writeFile(file: dockerFileLocation, text: dockerFile)
}

