# language: ja

機能: ファイルシステム
  ファイルシステムをマウントし
  ファイル操作の基本的なコマンドを実行することで
  ファイルシステムを利用するクライアントの視点でテストする

  シナリオ: ファイルを作成する
    前提: マウントポイントに移動する
    もし: 以下の内容のファイルを作成する
      | filename | content  |
      | hoge.txt | hogehoge |
    ならば: ディレクトリに "hoge.txt" が存在する
    かつ: "hoge.txt" の内容に "hogehoge" が含まれている

  シナリオ: ファイルに追記する
    前提: マウントポイントに移動する
    前提: 以下の内容のファイルを作成する
      | filename | content  |
      | hoge.txt | hogehoge |
    前提: ディレクトリに "hoge.txt" が存在する
    もし: "hoge.txt" に "hugahuga" を追記する
    ならば: "hoge.txt" の内容に "hogehoge" が含まれている
    かつ: "hoge.txt" の内容に "hogehogehugahuga" が含まれている
