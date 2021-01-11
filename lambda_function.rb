require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'
require 'aws-record'


class GoodEatsReviews
  include Aws::Record
  integer_attr :id, hash_key: true
  string_attr :author_name
  integer_attr :rating
  string_attr :text
  string_attr :relative_time_description
end

module Area
  # ぐるなびAPIで定められているエリアコード（AREAS2156: 池袋東口・東池袋）AREAS5566(月寒)
  CODES = ['AREAS5566']
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
  resource = "https://maps.googleapis.com/maps/api/place/details/json?key=#{ENV['GOOGLE_MAP_API_KEY']}&place_id=#{place_id}&language=ja"
  place = fetch_data(resource)
  # rating = place['result']['rating']
  reviews = place['result']['reviews']
  return unless reviews
  reviews
end

def put_item(restaurant_id, review) # DynamoDBへ保存
  return if GoodEatsReviews.find(id: restaurant_id, author_name: review['author_name']) # 既にDynamoDBに同じIDのレコードが存在した場合は新たに保存しない
  review = GoodEatsReviews.new
  review.id = restaurant_id
  review.author_name = review['author_name']
  review.rating = review['rating']
  review.text = review['text']
  review.relative_time_description = review['relative_time_description']
  review.save
end

def lambda_handler
  Area::CODES.each do |code|
    resource = "https://api.gnavi.co.jp/RestSearchAPI/v3/?keyid=#{ENV['GNAVI_API_KEY']}&areacode_s=#{code}"
    restaurants = fetch_data(resource)
    restaurants.each do |restaurant|
      puts restaurant['rest']
    end
  end
end

# get_place_id("磯丸水産")
# get_reviews("ChIJAQCMGdiMGGARi39obFln_1E")

lambda_handler()
