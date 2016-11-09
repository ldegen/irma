var fs = require("fs");
var path = require("path");
var p = require("./package.json");
p.bundleDependencies = Object.keys(p.dependencies);
fs.writeFileSync(path.join(__dirname, 'package.json'), JSON.stringify(p, null, '  '));
