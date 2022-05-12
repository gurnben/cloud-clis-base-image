FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

# Set the working directory (to better tolerate all of the clis dotfiles)
ENV HOME=/tmp
WORKDIR $HOME

# Install microdnf packages: tar/gzip, curl, git, jq, htpasswd
RUN microdnf update -y && microdnf install -y tar gzip curl git jq httpd-tools findutils unzip which make wget python3 gcc

# Install golang because we can't have nice things and microdnf install it
RUN curl "https://dl.google.com/go/$(curl https://go.dev/VERSION?m=text).linux-amd64.tar.gz" -o go.linux-amd64.tar.gz && \
    rm -rf /usr/local/go && tar -C /usr/local -xzf go.linux-amd64.tar.gz && \
    echo "export PATH=$PATH:/usr/local/go/bin" >> $HOME/profile && \
    source $HOME/profile && \
    go version
    # rm -rf go.linux-amd64.tar.gz;

# Install kustomize
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

# Build and add hiveutil to our container
RUN source $HOME/profile && \
    git clone https://github.com/openshift/hive.git && \
    cd hive && \
    make build && \
    mv ./bin/hiveutil /usr/local/bin && \
    cd .. && \
    rm -rf hive;

# Install the Azure CLI
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    echo -e "[azure-cli]\n\
name=Azure CLI\n\
baseurl=https://packages.microsoft.com/yumrepos/azure-cli\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/azure-cli.repo && \
    microdnf install azure-cli

# Install awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install \
    && rm -rf awscliv2.zip

# Install GCP CLI
RUN curl --silent --location https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-378.0.0-linux-x86_64.tar.gz --output google-cloud-sdk.tar.gz && \
    tar xzf google-cloud-sdk.tar.gz && \
    ./google-cloud-sdk/install.sh --path-update=true --quiet && \
    rm -rf google-cloud-sdk.tar.gz

# Install rosa cli
RUN curl -sLO https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/rosa/latest/rosa-linux.tar.gz -o rosa-linux.tar.gz && \
    tar xzf rosa-linux.tar.gz --no-same-owner && \
    mv rosa /usr/local/bin/rosa && \
    rm -rf rosa-linux.tar.gz

# Install eks cli
RUN curl --silent --location https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin

# Install oc/kubectl
RUN curl -sLO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz -o openshift-client-linux.tar.gz && \
    tar xzf openshift-client-linux.tar.gz --no-same-owner && \
    chmod +x oc && mv oc /usr/local/bin/oc && \
    chmod +x kubectl && mv kubectl /usr/local/bin/kubectl && \
    rm openshift-client-linux.tar.gz

# Clean up yum and dnf artifacts
RUN rm -rf /var/cache /var/log/dnf* /var/log/yum.*
