FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

# Set the working directory (to better tolerate all of the clis dotfiles)
ENV HOME=/tmp
WORKDIR $HOME

# Install microdnf packages: tar/gzip, curl, git, jq, htpasswd
RUN microdnf update -y && microdnf install -y tar gzip curl git jq httpd-tools findutils unzip which
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc
RUN echo -e "[azure-cli]\n\
name=Azure CLI\n\
baseurl=https://packages.microsoft.com/yumrepos/azure-cli\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/azure-cli.repo
RUN microdnf install azure-cli

# Install awscli for EKS and ROSA
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install;

# Install rosa cli
RUN curl -sLO https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/rosa/latest/rosa-linux.tar.gz -o rosa-linux.tar.gz && \
    tar xzf rosa-linux.tar.gz && chmod +x rosa && mv rosa /usr/local/bin/rosa;

# Install eks cli
RUN curl --silent --location https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin

# Install oc/kubectl
RUN curl -sLO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz -o openshift-client-linux.tar.gz && \
    tar xzf openshift-client-linux.tar.gz && chmod +x oc && mv oc /usr/local/bin/oc && \
    chmod +x kubectl && mv kubectl /usr/local/bin/kubectl && rm openshift-client-linux.tar.gz
