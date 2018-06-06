:


# mangler også nginx

cd /tmp
git clone https://github.com/deic-dk/gossamer.git
cd gossamer
npm i npm@latest -g

npm install
npm install -g bower
npm install -g ember-cli

apt-get install build-essential chrpath libssl-dev libxft-dev libfreetype6-dev libfreetype6 libfontconfig1-dev libfontconfig1 -y
npm -g install phantomjs-prebuilt --unsafe-perm
# npm install -g phantomjs-prebuilt --ignore-scripts
# npm install -g phantomjs@2.1.1 --unsafe-perm
# npm -g install phantomjs-prebuilt --upgrade --unsafe-perm

npm cache clean --force
bower install --allow-root
bower install semantic-ui --allow-root

ember generate semantic-ui-ember

npm install -g gulp

cd bower_components/semantic-ui/
npm install --unsafe-perm
npm audit fix --force

# håbløst: det ser ikke ud som på ww1/ww2
