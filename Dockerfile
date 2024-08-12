FROM hashicorp/terraform:1.3.6

COPY git-credentials-helper.sh /root/.git-credentials-helper.sh
WORKDIR /terraform

RUN chmod +x /root/.git-credentials-helper.sh
RUN git config --global credential.helper '/root/.git-credentials-helper.sh'

ENTRYPOINT ["/bin/sh"]
