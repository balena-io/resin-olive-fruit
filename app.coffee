os = require('os')
path = require('path')
async = require('async')
uuid = require('node-uuid')
request = require('request')
geoip = require('geoip-lite')
{spawn} = require('child_process')

INTERVAL = 1000#*60
ENTRYPOINT = 'http://thomporter-nodejs-77230.use1.nitrousbox.com/api/v1/photo-upload'

getPhoto = (callback) ->
	id = uuid.v4()
	photo = path.join(os.tmpdir(), id+'.jpg')

	raspistill = spawn('echo', [photo])
	#raspistill = spawn('raspistill', ['-o', photo])
	raspistill.on('error', (error) ->
		callback(error)
	)
	raspistill.on('exit', (code) ->
		if code == 0
			callback(null, id, photo)
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
				#curl -i -X POST -F "photo=@/root/$uuid.jpg" -F 'farm_id=fg5Gh8sQ3nng3hsW3tr4s' -F 'camera_id=xg5Gh8sQ3nn25hsW3tr4s' -F 'photo_id=$uuid' -F 'timestamp=2014-02-08T03:35:26.723Z' -F 'gps_location=38.239259,-85.735073' 'http://thomporter-nodejs-77230.use1.nitrousbox.com/api/v1/photo-upload'
				console.dir results
				setTimeout(callback, INTERVAL, null)
		)

	(error) ->
		console.error 'ERROR:', error
)
