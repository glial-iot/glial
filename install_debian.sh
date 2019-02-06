apt-get -y update
apt-get -y install gnupg2 lsb-release curl apt-transport-https
curl http://download.tarantool.org/tarantool/1.10/gpgkey | apt-key add -
release=`lsb_release -c -s`
rm -f /etc/apt/sources.list.d/*tarantool*.list
echo "deb http://download.tarantool.org/tarantool/1.10/debian/ ${release} main" > /etc/apt/sources.list.d/tarantool_1_10.list
echo "deb-src http://download.tarantool.org/tarantool/1.10/debian/ ${release} main" >> /etc/apt/sources.list.d/tarantool_1_10.list

apt-get -y update
apt-get -y install tarantool

curl -sL https://deb.nodesource.com/setup_11.x | -E bash -
apt-get install -y nodejs build-essential
