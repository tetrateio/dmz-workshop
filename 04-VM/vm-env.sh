# bin/bash
sudo service docker start

echo "Using EC2 instance metadata to lookup IPs...."
export EXTERNAL_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
export INTERNAL_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
echo "External IP: $EXTERNAL_IP"
echo "Internal IP: $INTERNAL_IP"
