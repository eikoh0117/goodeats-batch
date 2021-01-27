# GoodEats batch
Lambda関数として配置

## 使用言語
Ruby 2.7.0

## 用途
飲食店に対して投稿されたGoogle PlacesのレビューをDynamoDB上に集積することを目的とする
 
## DB
GoodEatsReviews

### Schema
| Key | Value (example) | Type |
| - | - | - | 
| restaurant_id | J000000000 | string |
| place_id | ChlJ27hogehogefugafuga | string |
| author_name | Hidemitsu Aoki | string |
| rating | 5 | integer |
| relative_time_description | 1ヶ月前 | string |
| text | 分煙が徹底されており、とても居心地が良い | string |

### restaunrant_id
[リクルートWEBサービス（ホットペッパーグルメ）](https://webservice.recruit.co.jp/doc/hotpepper/reference.html)で定められた飲食店に与えられている一意なID

### place_id
[Google Places API](https://cloud.google.com/maps-platform/places/)で定められたプレイスに与えられている一意なID

### author_name
レビューを投稿したGoogleユーザーの名前

### rating
投稿されたレビューで設定された数値（1 <= rating <= 5）

### relative_time_description
レビューが投稿された時期

### text
レビューの内容
