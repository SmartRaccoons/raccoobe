fs = require('fs')
pjson = require('./package.json')
exec = require('child_process').exec
_ = require('lodash')
node_ssh = require('node-ssh')
template = require('./template/generate')


module.exports = (grunt) ->
  grunt.loadNpmTasks('grunt-contrib-watch')
  coffee = [
    'public/d/js/*/*.coffee'
    'public/d/js/*.coffee'
    'public/d/locale/*.coffee'
    'public/d/*.coffee'
  ]
  coffee_command = "coffee -m -c"
  exec_callback = (error, stdout, stderr)->
    if error
      console.log('exec error: ' + error)

  grunt.registerTask 'termi', ->
    done = @async()
    ssh = new node_ssh()
    ssh.connect({
      host: 'termi.lv'
      username: 'piisiitiis'
      privateKey: '/Users/bambis/.ssh/id_rsa'
    })
    .then =>
      ssh.execCommand('git pull', { cwd:'/www/raccoobe/master/' }).then (result)->
        if result.stdout
          console.log(result.stdout)
        if result.stderr
          console.log('STDERR: ' + result.stderr)
        done()
    .catch =>
      console.info arguments
      done()

  grunt.registerTask 'compile', ->
    done = this.async()
    platforms = ['index', 'cocoon']
    platforms_exec = (i)=>
      pl = platforms[i]
      template.generate({platform: pl}, pl)
      exec "cat #{template.js_get(pl).join(' ')} > all-temp.js"
      exec "uglifyjs --beautify \"indent-level=0\" all-temp.js -o public/d/j-#{pl}.js", =>
        exec "rm all-temp.js"
        i++
        if i >= platforms.length
          done()
        else
          platforms_exec(i)
    platforms_exec(0)

  grunt.registerTask 'compile-cocoon', ->
    done = this.async()
    path = '../Raccoobe-cocoon'
    exec "mkdir #{path}"
    exec "mkdir #{path}/d"
    exec "cp public/d/j-cocoon.js #{path}/d/j-cocoon.js", =>
      exec "cp public/cocoon.html  #{path}/index.html", =>
        exec "cd #{path} && zip -r ../Archive.zip *", =>
          exec "rm -R #{path}"
          done()

  grunt.registerTask 'version', ->
    dir = __dirname + '/public/v/' + pjson.version
    if !fs.existsSync(dir)
      fs.mkdirSync(dir)
      fs.mkdirSync("#{dir}/d")
      fs.mkdirSync("#{dir}/d/css")
      fs.mkdirSync("#{dir}/d/images")
      fs.mkdirSync("#{dir}/d/sound")
    exec "cp -r public/d/font/ #{dir}/d/font/"
    exec "find public/d/images -maxdepth 1 -type f -exec cp {} #{dir}/d/images/ \\;"
    exec "cp -r public/stage/ #{dir}/stage/"
    exec "cp -r public/d/sound/ #{dir}/d/sound/"
    ['index.html',
      'offline.html',
      'd/j.js',
      'd/j-offline.js',
      'd/css/c.css'
    ].forEach (f)->
      exec "cp public/#{f} #{dir}/#{f}"

  grunt.initConfig
    watch:
      coffee:
        files: coffee
      sass:
        files: ['public/d/sass/screen.sass']
      static:
        files: ['public/d/**/*.css',
          'public/**/*.html',
          'public/**/*.js'],
        options:
          livereload: true
    compile:
      coffee:
        files: coffee

  grunt.event.on 'watch', (event, file, ext)->
    if ext == 'coffee'
#      console.info("compiling: #{file}")
      exec("#{coffee_command} #{file}", exec_callback)
    if ext == 'sass'
#      console.info("compiling: #{file}")
      exec("cd public/d && compass compile --sourcemap sass/screen.sass", exec_callback)

  grunt.registerTask('default', ['watch'])
