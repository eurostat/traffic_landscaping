# Enrich the statistics:

from google.transit import gtfs_realtime_pb2
import requests

feed = gtfs_realtime_pb2.FeedMessage()
# requests will fetch the results from a url, in this case, the positions of all Romes buses
location = 'https://dati.comune.roma.it/catalog/dataset/a7dadb4a-66ae-4eff-8ded-a102064702ba/resource/d2b123d6-8d2d-4dee-9792-f535df3dc166/download/rome_vehicle_positions.pb'

response =   requests.get(location)       
feed.ParseFromString(response.content)

bus = feed.entity[1]
bus
id: "2"
is_deleted: false
vehicle {
  trip {
    trip_id: "0#935-8"
    start_time: "20:03:00"
    start_date: "20220502"
    route_id: "115"
    direction_id: 0
  }
  position {
    latitude: 41.89421844482422
    longitude: 12.460575103759766
    odometer: 11242.0
  }
  current_stop_sequence: 7
  current_status: IN_TRANSIT_TO
  timestamp: 1651515194
  stop_id: "72864"
  vehicle {
    id: "195"
    label: "0244"
  }
}
