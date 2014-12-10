npm install node-gyp
rm -rf node_modules/protagonist
git clone git://github.com/apiaryio/protagonist.git node_modules/protagonist
cd node_modules/protagonist
git submodule update --init --recursive
node-gyp configure
node-gyp build
