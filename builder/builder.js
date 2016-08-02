var fs = require("fs");
var path = require("path");
var exec = require("child_process").exec;

var projectRootDirectory = path.dirname(process.argv[1]);
var rgbdsBinDirectory = path.resolve(__dirname, "bin");
var manifest = JSON.parse(fs.readFileSync(path.resolve(projectRootDirectory, "manifest.json")));

var buildDirectory = path.resolve(projectRootDirectory, "build");
var objectDirectory = path.resolve(buildDirectory, "obj");
var binDirectory = path.resolve(buildDirectory, "bin");

if(manifest == null) {
  console.log("Error: Must have manifest.json");
}

function run(command, done) {
  var runningProcess = exec(command);
  runningProcess.stdout.pipe(process.stdout);
  runningProcess.stderr.pipe(process.stderr);
  runningProcess.on("close", function(code) {
    if(code == 0) {
      if(done) {
        done();
      }
    } else {
      process.exit(code);
    }
  });
}

function ensureDirectoryExists(directory) {
  try {
    fs.statSync(directory);
  } catch(error) {
    fs.mkdirSync(directory);
  }
}

function makeDirectories(done) {
  ensureDirectoryExists(buildDirectory);
  ensureDirectoryExists(objectDirectory);
  ensureDirectoryExists(binDirectory);
  
  done();
}

function writeLinkFile(done) {
  var output = "";
  output += "[Objects]\n";
  output += "build/obj/main.o\n";
  output += "\n";
  output += "[Output]\n";
  output += "build/bin/" + manifest["fileName"] + ".gb\n";
  
  fs.writeFileSync(path.resolve(projectRootDirectory, "linkfile"), output);
  
  done();
}

function convertGraphics(done) {
  var imageDirectory = path.resolve(projectRootDirectory, "img");
  
  require("./gfx")(imageDirectory, done);
}

function gbasm(done) {
  run("gbasm main.asm", done);
}

function assemble(done) {
  run(path.resolve(rgbdsBinDirectory, "asm") + " -zFF -obuild/obj/main.o main.asm", done);
}

function link(done) {
  run(path.resolve(rgbdsBinDirectory, "link") + " -zFF -mbuild/bin/" + manifest["fileName"] + ".map -nbuild/bin/" + manifest["fileName"] + ".sym linkfile", done);
}

function fix(done) {
  run(path.resolve(rgbdsBinDirectory, "rgbfix") + " -pFF -v build/bin/" + manifest["fileName"] + ".gb", done);
}

function cleanup(done) {
  fs.unlinkSync(path.resolve(projectRootDirectory, "linkfile"));
  
  done();
}

function dropbox(done) {
  if(manifest["dropbox"] == true) {
    var dropboxDir = path.resolve(require('os-homedir')(), "Dropbox");
    var gbDir = path.resolve(dropboxDir, "GB");
    var projectDir = path.resolve(gbDir, manifest["fileName"]);
    
    ensureDirectoryExists(gbDir);
    ensureDirectoryExists(projectDir);
    
    fs.writeFileSync(path.resolve(projectDir, manifest["fileName"] + ".gb"), fs.readFileSync(path.resolve(binDirectory, manifest["fileName"] + ".gb")));
    fs.writeFileSync(path.resolve(projectDir, manifest["fileName"] + ".map"), fs.readFileSync(path.resolve(binDirectory, manifest["fileName"] + ".map")));
    fs.writeFileSync(path.resolve(projectDir, manifest["fileName"] + ".sym"), fs.readFileSync(path.resolve(binDirectory, manifest["fileName"] + ".sym")));
  }
  
  done();
}

var jobs = [
  makeDirectories,
  writeLinkFile,
  convertGraphics,
  // gbasm,
  assemble,
  link,
  fix,
  cleanup,
  dropbox
]

function main() {
  var jobIndex = 0;
  var nextJob = function() {
    if(jobIndex == jobs.length) {
      return;
    }
    
    var job = jobs[jobIndex];
    jobIndex++;
    job(nextJob);
  }
  
  nextJob();
}

main();
