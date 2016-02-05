Package.describe({
  "summary": "Easily include ace, receive reactive varibles for cursor position, editor contents, etc",
  "version": "0.0.44",
  "name": "dcsan:reactive-ace",
  "git": 'https://github.com/dcsan/meteor-reactive-ace.git'
});

var bundlerApi = null
var path = Npm.require("path");
var fs = Npm.require("fs");

if (process.env.PACKAGE_DIRS) {
  // console.log("dirName:", __dirname);  // breaks
  // console.log(require.main.filename);
  // packagesDevDir = "/" 
  // var packagePath = path.join(path.resolve("."), packagesDevDir );
  var packageRoot=process.env.PACKAGE_DIRS
} else {
  // find packages in appDir
  var packageRoot = path.join(path.resolve("."), "packages");
}

packagePath = path.join(packageRoot, "reactive-ace");



Package.on_use(function (api, where) {
  api.use([
    'jquery@1.0.0',
    "templating@1.0.0",
    "coffeescript@1.0.0",
    "underscore@1.0.0",
    "deps@1.0.0"
  ], ["client"]);

  //changed to use pre-included ace version
  // var srcPath = path.join(packagePath, "ace-builds", "src")
  var srcPath = path.join(packagePath, "vendor", "ace", "src")
  var files = fs.readdirSync(srcPath);

  files.forEach(function(file){
    //console.log("add_file", file)
    if (file === "snippets"){return;}
    addPath = path.join("vendor", "ace", "src", file);
    api.add_files(addPath, "client", {isAsset: true});
  });

  var snippets = fs.readdirSync(path.join(packagePath, "ace-builds", "src", "snippets"));
  snippets.forEach(function(file){
    snippetPath = path.join("ace-builds", "src", "snippets", file)
    api.add_files(snippetPath, "client", {isAsset: true});
  })

  api.add_files([
    "ace-builds/src/ace.js", 
    "ace-builds/src/ext-modelist.js", 
    "lib/utils.coffee", 
    "lib/crc32.js", 
    "lib/esprima.js", 
    "editor.coffee", 
    "editorSetup.coffee", 
    "templates.html"
  ], "client");

});
