# Once https://github.com/npm/npm/issues/1876 is fixed or new Protagonist is released,
# this script won't be necessary anymore. To deprecate it, follow these steps:
#
# 1. Add latest Protagonist to optionalDependencies in package.json.
# 2. Remove this script.
# 3. Edit comments and messages in generate-samples-ast.coffee.
#
rm -rf node_modules/protagonist
git clone git://github.com/apiaryio/protagonist.git node_modules/protagonist -b zdne/attributes-description
cd node_modules/protagonist
git submodule update --init --recursive
npm install node-gyp
node node_modules/node-gyp/bin/node-gyp.js configure
node node_modules/node-gyp/bin/node-gyp.js build
