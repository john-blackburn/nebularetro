const hostname = 'localhost'
const port = 80
const dbfile = './levels.json'
const maxbodysize = 8000
const maxnamesize = 32
const lengthsize = 4
const maxlevels = 1000000

const fs = require('fs')
const http = require('http')

function loadLevels() {
  let filedesc
  try {filedesc = fs.openSync(dbfile, 'r+')}
  catch (e) {fs.appendFileSync(dbfile, '{'); return {}}
  let filesize = fs.statSync(dbfile).size
  if (filesize == 1) return {}  
  fs.writeSync(filedesc, '}', filesize-1)
  const levels = require(dbfile)
  fs.writeSync(filedesc, ',', filesize-1)
  fs.closeSync(filedesc)
  return levels
}

const levels = loadLevels()

const names = Buffer.alloc(maxnamesize * maxlevels, ' ')
let maximum = 0
for (name in levels) names.write(name, maximum++ * maxnamesize)

const codes = {
  67: 'COUNT',
  68: 'DOWNLOAD',
  78: 'NAMES',
  85: 'UPLOAD',
}

const server = http.createServer((req, res) => {
    req.on('data', data => {
      const len = data.length
      const code = codes[data[0]]
      if (len > maxbodysize || !code) {
        res.writeHead(200, "NO", {'Content-Type': 'text/html'})
        res.end()
        return
      }
      switch (code) {
        case 'UPLOAD':
          const name = data.toString(undefined, 1, 1 + maxnamesize).trim()
          if (!/^[\x20-\x7F]*$/.test(name))
            res.writeHead(200, "NO", {'Content-Type': 'text/html', 'upload': "NAME"})
          else if (levels[name])
            res.writeHead(200, "NO", {'Content-Type': 'text/html', 'upload': "BUSY"})
          else {
            const level = data.toString(undefined, 1 + maxnamesize, len)
            levels[name] = level
            names.write(name, maximum++ * maxnamesize)
            fs.appendFile(dbfile, JSON.stringify({[name]: level}).slice(1, -1)+",")
            res.writeHead(200, "OK", {'Content-Type': 'text/html',  'upload': "OK"})
          }
          break
        case 'COUNT':
          res.writeHead(200, "OK", {'Content-Type': 'text/html', 'maximum': maximum})
          break
        case 'NAMES':
          const p1 = (data.readUInt32BE(1) - 1) * maxnamesize
          const p2 = data.readUInt32BE(5) * maxnamesize
          if (p2 - p1 < maxbodysize) res.writeHead(200, "OK", {'Content-Type': 'text/html',
            'names': names.toString(undefined, p1, p2)})
          else res.writeHead(200, "NO", {'Content-Type': 'text/html'})
          break
        case 'DOWNLOAD':
          res.writeHead(200, "OK", {'Content-Type': 'text/html',
            'level': levels[data.toString(undefined, 1, len)]})
          break
      }
      res.end()
    })
})

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`)
})