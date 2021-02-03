# camelot-mhlw
厚生労働省サイトが提供している「国内における都道府県別のPCR検査陽性者数」PDFファイル （[例](https://www.mhlw.go.jp/content/10906000/000732231.pdf)）から各都道府県の陽性者数、検査数、陽性率データを抽出するための docker イメージを構築する Dockerfile と、抽出に用いる python スクリプトです。

camelot という python モジュールを利用しています。

実際に抽出した日々のテキストファイルも格納してあります。


## Docker イメージのビルド
### docker コマンドを実行する場合
``` shell
docker build -t camelot-mhlw .
```
タグ名は適当に変更してください。

### docker-compose を用いる場合
``` shell
docker-compose build
```
イメージのタグ名は "camelot-mhlw" になります。

## PDFからテキスト抽出を実行
まず、次のコマンドを実行してください。（タグ名はビルド時に付けた名前を使ってください）
``` shell
docker run --rm -v $(pwd)/mhlw_pdf:/mhlw_pdf camelot-mhlw sh /root/latest_pdf_to_text.sh
```
または docker-compose を使って
``` shell
docker-compose run --rm camelot
```
でも結構です。

標準出力に次のようなデータが表示されればOKです。
```
PDF_FILE|/mhlw_pdf/20210202.pdf
都道府県名|陽性者数 検査人数||％
北海道|17,521|321,207|5.5%
青森|717|13,318|5.4%
[中略]
鹿児島|1,632|56,203|2.9%
沖縄|7,585|126,082|6.0%
長崎船 その他|149|0|-
合計|389,457|6,437,569|6.0%
```

新しいPDFをダウンロードしたら、`yyyymmdd.pdf` 形式の名前にして `mhlw_pdf/` ディレクトリに格納してから上記コマンドを実行してください。最新日付のPDFファイルに対してテキスト抽出が実行されます。

なお、日々抽出したテキストファイルを `mhlw_pref` ディレクトリに格納してあります（PDFファイルとは日付が1日ずれているので注意）。毎日更新予定。

テキストファイルをcsvなどに整形する方法については `tools/make_pref_data.rb` を参考にしてください。

## 作者
Twitter: [@oktopus59](https://twitter.com/oktopus59) (OKA Toshiyuki)

何かご意見・ご要望があれば上記アカウントまでお願いします。
