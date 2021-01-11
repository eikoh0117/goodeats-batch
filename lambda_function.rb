require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'
require 'aws-record'


class GoodEats
  include Aws::Record
  integer_attr :id, hash_key: true
  integer_attr :restaurant_id
  integer_attr :name
  integer_attr :comment
  integer_attr :evaluation
  integer_attr :photo
  integer_attr :date
end

module Area
  # ぐるなびAPIで定められているエリアコード（AREAS2156: 池袋東口・東池袋）
  CODES = ['AREAS2115']
end

def fetch_data(resource)
  enc_str = URI.encode(resource)
  uri = URI.parse(enc_str)
  json = Net::HTTP.get(uri)
  JSON.parse(json)
end

def get_place_id(restaurant_name)
  # Google Places APIを使って口コミの情報を取得
  resource = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=#{restaurant_name}&key=#{ENV['GOOGLE_MAP_API_KEY']}&language=ja"
  places = fetch_data(resource)
  return unless places['results'].first # 店舗が存在しないときはnilを返す
  places['results'][0]['place_id']
end

def get_reviews(place_id)
end

get_place_id("磯丸水産")
