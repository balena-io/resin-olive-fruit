fs = require('fs')
os = require('os')
path = require('path')
async = require('async')
uuid = require('node-uuid')
request = require('request')
geoip = require('geoip-lite')
{spawn} = require('child_process')

INTERVAL = 1000*60
ENTRYPOINT = 'http://thomporter-nodejs-77230.use1.nitrousbox.com/api/v1/photos'

# load demo data
demo = JSON.parse((fs.readFileSync('demo.json', 'utf8')))

getRandomElement = (arr) ->
	return arr[Math.floor(Math.random()*arr.length)]

getRandomData = (data) ->
	farm = getRandomElement(data)
	camera = getRandomElement(farm.cameras)
	return {
		farm_id: farm.id
		camera_id: farm.id + camera.id
		gps_location: camera.ll
	}

getPhoto = (callback) ->
	photo = path.join(os.tmpdir(), uuid.v4()+'.jpg')

	raspistill = spawn('echo', [photo])
	#raspistill = spawn('raspistill', ['-o', photo])
	raspistill.on('error', (error) ->
		callback(error)
	)
	raspistill.on('exit', (code) ->
		if code == 0
			callback(null, photo)
		else
			callback('raspistill exited with code '+code)
	)

geoIPLocation = (callback) ->
	request('http://whatismyip.akamai.com/', (error, response, body) ->
		if error?
			callback(error)
			return

		if response.statusCode != 200
			callback('Failed to get IP address from http://whatismyip.akamai.com/')
			return

		geo = geoip.lookup(body)
		callback(null, geo)
	)

async.forever(
	(callback) ->
		async.parallel([
			(callback) ->
				getPhoto(callback)
			#(callback) ->
			#	geoIPLocation(callback)
		], (error, results) ->
			if error?
				callback(error)
			else
				[[photo]] = results
				data = getRandomData(demo)

				console.dir results
				console.dir data

				req = request.post(ENTRYPOINT, (error, response, body) ->
					if error?
						callback(error)
						return

					if response.statusCode != 200
						callback('Server returned '+response.statusCode)
						return

					setTimeout(callback, INTERVAL, null)
				)

				form = req.form()
				form.append('photo', fs.createReadStream(photo))
				form.append('farm', data.farm_id)
				form.append('camera', data.camera_id)
				form.append('timestamp', Date.now())
				form.append('gps_location', data.gps_location.join(','))
		)

	(error) ->
		console.error 'ERROR:', error
)
