# ubuntu:latest doesn't work (22.04 LTS)
FROM ubuntu:20.04

RUN apt-get update
RUN apt-get install -y \
    wget \
    unzip

WORKDIR /app

ENV GODOT_VERSION "3.5"

RUN wget https://downloads.tuxfamily.org/godotengine/3.5/Godot_v3.5-stable_linux_server.64.zip
RUN unzip Godot_v3.5-stable_linux_server.64.zip
RUN rm -rf Godot_v3.5-stable_linux_server.64.zip

COPY build/Server.pck Server.pck

EXPOSE 44444

ENTRYPOINT ["./Godot_v3.5-stable_linux_server.64", "-d", "--main-pack", "Server.pck"]

