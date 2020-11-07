# symbol-testnet-node-startup-script

Symbol ブロックチェーンのテストネットノードのスタートアップスクリプトです。動作検証は十分ではない可能性がありますのでその点はご注意ください。

## 対象バージョン

symbol-bootstrap v0.2.0

## 参考資料

よしゆきさんの以下資料を参考にさせて頂きました。ありがとうございます。

- [https://nemlog.nem.social/blog/49345](https://nemlog.nem.social/blog/49345)
- [https://github.com/44uk/symbol-testnet-node-running-hands-on](https://github.com/44uk/symbol-testnet-node-running-hands-on)

## 使い方

DNS を各自適切に設定した上で、`startup-script.sh`の中の、ドメインの`symbol-testnet-node.next-web-technology.com`の部分を各自のドメインに合わせて修正して、スタートアップスクリプトとして実行することで、SSL 化済の状態でノードを起動させることができます。

GCP 上での実行を前提として、メモリ使用量等の監視を行うツールのインストールも同時に行っています。
他プラットフォームでの利用の際は、`# Install Cloud Monitoring Agent`以降の箇所は不要ですので、適宜削除する等してご利用ください。

なお、一度起動した後は、このスタートアップスクリプトは削除しておきましょう。
