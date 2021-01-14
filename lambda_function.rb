require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'
require 'aws-record'


class GoodEatsReviews
  include Aws::Record
  integer_attr :restaurant_id, hash_key: true
  integer_attr :place_id, hash_key: true
  string_attr :author_name
  integer_attr :rating
  string_attr :text
  string_attr :relative_time_description
end

module Area
  # ぐるなびAPIで定められているエリアコード（AREAS2156: 池袋東口・東池袋）AREAS5566(月寒)
  # CODES = ['AREAS5566']
  CODES = ['AREAS2115']
end

module Category
  # ぐるなびAPIで定められている大業態コード
  CODES = ['RSFST09000', 'RSFST02000', 'RSFST03000', 'RSFST04000', 'RSFST05000', 'RSFST06000', 'RSFST01000', 'RSFST07000', 'RSFST08000', 'RSFST14000', 'RSFST11000', 'RSFST13000', 'RSFST12000', 'RSFST16000', 'RSFST15000', 'RSFST17000', 'RSFST10000', 'RSFST21000', 'RSFST18000', 'RSFST19000', 'RSFST20000', 'RSFST90000']
end

def

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

def put_item(restaurant_id, place_idreview) # DynamoDBへ保存
  return if GoodEatsReviews.find(id: restaurant_id, author_name: review['author_name']) # 既にDynamoDBに同じIDのレコードが存在した場合は新たに保存しない
  review = GoodEatsReviews.new
  review.restaurant_id = restaurant_id
  review.place_id = place_id
  review.author_name = review['author_name']
  review.rating = review['rating']
  review.text = review['text']
  review.relative_time_description = review['relative_time_description']
  review.save
end

def lambda_handler
  Area::CODES.each do |code|
    restaurants = []
    1...10.times do |i|
      resource = "https://api.gnavi.co.jp/RestSearchAPI/v3/?keyid=#{ENV['GNAVI_API_KEY']}&areacode_s=#{code}&hit_per_page=100&offset_page=#{i + 1}"
      response = fetch_data(resource)
      next if  response["error"]
      response['rest'].each do |item|
        restaurants.push(item)
      end
      if i == 9 && response['total_hit_count'] > 1000
        puts "success"
        1...10.times do |j|
          resource_second = "https://api.gnavi.co.jp/RestSearchAPI/v3/?keyid=#{ENV['GNAVI_API_KEY']}&areacode_s=#{code}&hit_per_page=100&offset_page=#{10 + j + 1}"
          response_second = fetch_data(resource_second)
          puts response_second
          next if response_second["error"]
          response_second['rest'].each do |item|
            restaurants.push(item)
          end
        end
      end
    end
    puts restaurants.length
  end
end

lambda_handler()
