# Build the new version of the server in the build/ directory using godot

SERVERIP="1.1.1.1"  # Change this ip for real deployment

scp -r build/Server.pck pilot@$SERVERIP:~/build/Server.pck
scp -r Dockerfile pilot@$SERVERIP:~/Dockerfile
ssh pilot@$SERVERIP 'docker build --tag "airportserver:latest" --no-cache .;docker kill $(docker ps -q);docker run -d --network host --restart on-failure airportserver:latest;docker ps'
