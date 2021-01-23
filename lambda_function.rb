require 'net/http'
require 'uri'
require 'json'
require 'addressable/uri'
require 'dotenv/load'
require 'aws-record'


class GoodEatsReviews # DynamoDBのテーブルを定義
  include Aws::Record
  string_attr :restaurant_id, hash_key: true
  string_attr :place_id, range_key: true
  string_attr :author_name
  integer_attr :rating
  string_attr :text
  string_attr :relative_time_description
end

module Area # ホットペッパーAPIで定められている小エリアコードを定義
  CODES = ['X150'] # 歌舞伎町
end

def fetch_data(resource) # URIを引数として入力するとJSON形式でレスポンスが出力される汎用的な関数
  enc_str = Addressable::URI.encode(resource)
  uri = URI.parse(enc_str)
  json = Net::HTTP.get(uri)
  JSON.parse(json)
end

def get_restaurants # hotpepper APIから飲食店の情報を取得する
  restaurants = []
  Area::CODES.each do |area|
    resource = "https://webservice.recruit.co.jp/hotpepper/gourmet/v1/?key=#{ENV['RECRUIT_API_KEY']}&small_area=#{area}&order=4&count=100&format=json"
    response = fetch_data(resource)
    results = response['results']
    hit_count = results['results_available']
    next if hit_count === 0
    shops = results['shop']
    shops.each do |shop|
      id = shop['id']
      name = shop['name']
      area_name = shop['small_area']['name']
      restaurant = {id: id, name: name, area: area_name}
      restaurants.push(restaurant)
    end
    if hit_count > 100
      total_pages = (hit_count / 100).to_i
      1...total_pages.times do |i|
        second_resource = "https://webservice.recruit.co.jp/hotpepper/gourmet/v1/?key=#{ENV['RECRUIT_API_KEY']}&small_area=#{area}&order=4&count=100&start=#{(i + 1) * 100 + 1}&format=json"
        second_response = fetch_data(second_resource)
        second_results = second_response['results']
        next if second_results['results_returned'] === "0"
        second_shops = second_results['shop']
        second_shops.each do |shop|
          second_id = shop['id']
          second_name = shop['name']
          second_area_name = shop['small_area']['name']
          second_restaurant = {id: second_id, name: second_name, area: second_area_name}
          restaurants.push(second_restaurant)
        end
      end
    end
  end
  restaurants
end

def get_place_id(shop_name, area) # Google Places APIの一意に与えられているplace_idを取得
  resource = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=#{shop_name} #{area}&key=#{ENV['GOOGLE_MAP_API_KEY']}&language=ja"
  places = fetch_data(resource)
  return unless places['results'].first # 店舗が存在しないときはnilを返す
  places['results'][0]['place_id']
end

def get_reviews(place_id) # place_idを用いて、レビューを取得
  resource = "https://maps.googleapis.com/maps/api/place/details/json?key=#{ENV['GOOGLE_MAP_API_KEY']}&place_id=#{place_id}&language=ja"
  place = fetch_data(resource)
  reviews = place['result']['reviews']
  return unless reviews
  reviews
end

def put_item(restaurant_id, place_id, review) # DynamoDBへ保存
  return if GoodEatsReviews.find(restaurant_id: restaurant_id, place_id: place_id, author_name: review['author_name']) # 既にDynamoDBに同じIDのレコードが存在した場合は新たに保存しない
  new_review = GoodEatsReviews.new
  new_review.restaurant_id = restaurant_id
  new_review.place_id = place_id
  new_review.author_name = review['author_name']
  new_review.rating = review['rating']
  new_review.text = review['text']
  new_review.relative_time_description = review['relative_time_description']
  new_review.save
end

def lambda_handler
  restaurants = get_restaurants
  restaurants.each do |restaurant|
    place_id = get_place_id(restaurant[:name], restaurant[:area])
    reviews = get_reviews(place_id)
    reviews.each do |review|
      put_item(restaurant[:id], place_id, review)
    end
  end
end

lambda_handler()
