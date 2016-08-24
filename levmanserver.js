const hostname = process.env.NODE_IP || 'localhost'
const port = process.env.NODE_PORT || 80
const dbfile = process.env.OPENSHIFT_DATA_DIR+'levels.json'
const maxbodysize = 8000
const maxnamesize = 32
const lengthsize = 4
const maxlevels = 100000

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
for (let name in levels) names.write(name, maximum++ * maxnamesize)

const hexpat = /^[0-9A-Fa-f]+$/

const server = http.createServer((req, res) => {
    const url = req.url
    const mode = url.slice(0, 3)
    let data = false
    let err = false
    
    if (mode == '/c/') {
        data = maximum
    } else if (mode == '/n/') {
        if (hexpat.test(url.slice(3))) {
            const p1 = parseInt(url.slice(3, 11), 16) * maxnamesize - maxnamesize
            const p2 = parseInt(url.slice(11, 19), 16) * maxnamesize
            console.log(p1, p2/maxnamesize)
            if (p2 - p1 < maxbodysize) data = names.toString('ascii', p1, p2)
        }
        err = 400
    } else if (mode == '/d/') {
        data = levels[url.slice(3)]
        err = 404
    } else if (mode == '/u/') {
        const body = url.slice(3)
        if (body.length > maxnamesize && hexpat.test(body)) {
            const name = url.slice(3, 3 + maxnamesize)
            const level = url.slice(3 + maxnamesize)
            if (levels[name]) err = 423
            else {
                levels[name] = level
                names.write(name, maximum++ * maxnamesize)
                fs.appendFile(dbfile, JSON.stringify({[name]: level}).slice(1, -1)+",")
            }
        } else err = 400
    }
    console.log(url, mode, data, err)
    data !== false ? res.writeHead(200, "OK", {data}) : res.writeHead(err || 200)
    res.end();
})

server.listen(port, hostname, () => {
    console.log(`Server running at http://${hostname}:${port}/`)
	console.log(`Database file at ${dbfile}`)
})