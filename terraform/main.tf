provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "allow_all" {
  name = "allow_all"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "devops" {
  ami           = "ami-0f5ee92e2d63afc18"
  instance_type = "t2.micro"
  key_name      = "jenkins-key"

  vpc_security_group_ids = [aws_security_group.allow_all.id]

  user_data = <<-EOF
#!/bin/bash

apt update -y

# DOCKER
apt install -y docker.io
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# KUBERNETES (K3s)
curl -sfL https://get.k3s.io | sh -

mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# JAVA
apt install -y openjdk-17-jdk

# JENKINS
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian binary/ | tee \
/etc/apt/sources.list.d/jenkins.list > /dev/null

apt update -y
apt install -y jenkins

systemctl start jenkins
systemctl enable jenkins

sleep 60

# INSTALL PLUGINS
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

java -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin git docker-workflow workflow-aggregator ssh-agent credentials-binding

systemctl restart jenkins

# CREATE JOB
cat <<EOT > /tmp/job.xml
<flow-definition plugin="workflow-job">
  <description>Auto DevOps Pipeline</description>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition">
    <scm class="hudson.plugins.git.GitSCM">
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/SaiVarun107/jenkins-terraform-k8s-deploy.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
  </definition>
</flow-definition>
EOT

sleep 60

java -jar jenkins-cli.jar -s http://localhost:8080/ create-job devops-pipeline < /tmp/job.xml
EOF

  tags = {
    Name = "FULL-AUTO-DEVOPS"
  }
}