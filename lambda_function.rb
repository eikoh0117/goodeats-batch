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
  # ホットペッパーAPIで定められている中エリアコード
  # CODES = ['Y005'] # 新宿
  # ホットペッパーAPIで定められている小エリアコード
  CODES = ['X150'] # 歌舞伎町
end

# module Category
#   # ぐるなびAPIで定められている大業態コード
#   CODES = ['RSFST09000', 'RSFST02000', 'RSFST03000', 'RSFST04000', 'RSFST05000', 'RSFST06000', 'RSFST01000', 'RSFST07000', 'RSFST08000', 'RSFST14000', 'RSFST11000', 'RSFST13000', 'RSFST12000', 'RSFST16000', 'RSFST15000', 'RSFST17000', 'RSFST10000', 'RSFST21000', 'RSFST18000', 'RSFST19000', 'RSFST20000', 'RSFST90000']
# end

def fetch_data(resource)
  enc_str = URI.encode(resource)
  uri = URI.parse(enc_str)
  json = Net::HTTP.get(uri)
  JSON.parse(json)
end

def get_place_id(shop_name, area)
  # Google Places APIを使って口コミの情報を取得
  resource = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=#{shop_name} #{area}&key=#{ENV['GOOGLE_MAP_API_KEY']}&language=ja"
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
  restaurants = []
  Area::CODES.each do |area|
    resource = "https://webservice.recruit.co.jp/hotpepper/gourmet/v1/?key=#{ENV['RECRUIT_API_KEY']}&small_area=#{area}&order=4&count=100&format=json"
    response = fetch_data(resource)
    results = response['results']
    hit_count = results['results_available']
    puts hit_count
    next if hit_count === 0
    shops = results['shop']
    shops.each do |shop|
      name = shop['id']
      name = shop['name']
      area = shop['small_area']['name']
      restaurant = {id: id, name: name, area: area}
      restaurants.push(restaurant)
    end
    # if hit_count > 100
    #   total_pages = (hit_count / 100).to_i
    #   1...total_pages.times do |i|
    #     puts i
    #   end
    # end







    #   1...10.times do |i|
    #     resource = "https://api.gnavi.co.jp/RestSearchAPI/v3/?keyid=#{ENV['GNAVI_API_KEY']}&areacode_s=#{area}&category_l=#{category}&hit_per_page=100&offset_page=#{i + 1}"
    #     response = fetch_data(resource)
    #     puts response
    #     # puts response
    #     # next if response['error']
    #     # puts response
    #     # response['rest'].each do |restaurant|
    #     #   puts restaurant
    #     # end
    #   end
    # end
  end
end

lambda_handler()
