minimatch = require 'minimatch'
UglifyJS = require 'uglify-js'


module.exports = class MagicWorker
    constructor: (ops) ->
        @ops = Object.assign {
            exclude: ['**.*map']
            include: ['/']
            minify: false
            options: {}
            target: 'sw.js'
        }, ops

    apply: (compiler) ->
        compiler.plugin 'emit', (compilation, cb) =>

            txt =  "\nvar CACHE_VERSION = '#{new Date().toJSON().slice(0,16).replace(/\D/g, '')}';\n"
            txt += "\nvar OPTIONS = #{JSON.stringify(@ops.options)};\n";

            txt += '\nvar ASSETS = [';

            txt += "\n  '#{fn}'," for fn in @ops.include

            @ops.exclude.push @ops.target

            for fn of compilation.assets
                unless @ops.exclude.some((p) -> minimatch fn, p, {matchBase: true, nocase: true})
                    txt += "\n  '#{fn}',"

            txt += '\n];\n\n'

            unless compilation.assets[@ops.target]?
                throw new Error '[MagicWorker] No Service Worker found with name: ' + @ops.target

            code = txt + compilation.assets[@ops.target].source().toString()

            code = UglifyJS.minify(code).code if @ops.minify

            compilation.assets[@ops.target] =
                source: -> code
                size: -> code.length

            cb()
