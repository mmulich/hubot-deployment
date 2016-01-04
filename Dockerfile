FROM ubuntu:14.04
RUN apt-get update && apt-get install -y git python-virtualenv python-dev
RUN useradd -m hubot
RUN git clone https://github.com/karenc/hubot-deployment.git /hubot-deployment
COPY vars/adapter.yml /hubot-deployment/vars/
RUN if [ -n "`grep '$ANSIBLE_VAULT;' /hubot-deployment/vars/adapter.yml`" ]; then echo "Need to decrypt vars/adapter.yml: ./bin/ansible-vault decrypt vars/adapter.yml"; exit 1; fi
WORKDIR /hubot-deployment
RUN virtualenv .
RUN ./bin/pip install ansible
RUN ./bin/ansible-galaxy install --roles-path=./roles -r requirements.yml
RUN ./bin/ansible-playbook -i docker-inventory site.yml
RUN apt-get clean && rm -rf /var/lib/apt/lists/* # make the image smaller
RUN chown -R hubot:hubot .
USER hubot
ENV REDIS_URL redis://redis/
EXPOSE 80
CMD /home/hubot/hubot/bin/start-hubot
