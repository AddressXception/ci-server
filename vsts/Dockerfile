FROM ci-server-base

# add an ssh key
WORKDIR /root
RUN mkdir -p /root/.ssh
RUN ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa

WORKDIR /

# copy the start script
COPY ./start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]