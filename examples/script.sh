apt-get update
apt-get upgrade -y

# Install package sources.
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
cp ./microsoft.gpg /etc/apt/trusted.gpg.d/

curl https://packages.microsoft.com/config/ubuntu/18.04/multiarch/prod.list > ./microsoft-prod.list
cp ./microsoft-prod.list /etc/apt/sources.list.d/

apt update

# Install Azure IoT Identity service.
apt install aziot-identity-service -y
apt install osconfig -y