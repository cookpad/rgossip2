require 'logger'
require 'msgpack'
require 'openssl'

module RGossip2

  #
  # class Context
  # ゴシッププロトコルのための各種変数格納クラス
  # ほとんどのクラスから参照される
  #
  class Context
    # ポート番号
    attr_accessor :port

    # バッファサイズと遊び
    # 「buffer_size * allowance + digest_length」が 65515bytes 以下になるようにする
    attr_accessor :buffer_size
    attr_accessor :attr_accessor

    # ハッシュ関数のアルゴリズムと長さ
    attr_accessor :digest_algorithm
    attr_accessor :digest_length

    # HMACの秘密鍵
    attr_accessor :auth_key

    # Nodeの寿命
    attr_accessor :node_lifetime

    # 送信インターバル
    attr_accessor :gossip_interval

    # 受信タイムアウト
    attr_accessor :receive_timeout

    # ロガー
    attr_accessor :logger

    # 各種ハンドラ
    attr_accessor :callback_handler
    attr_accessor :error_handler

    def initialize(options = {})
      # ハッシュのキーをシンボルに変換
      tmp = {}
      options.each {|k, v| tmp[k.to_sym] = v }
      options = tmp

      defaults = {
        :port             => 10870,
        :buffer_size      => 512,
        :allowance        => 3,
        :node_lifetime    => 10,
        :gossip_interval  => 0.1,
        :receive_timeout  => 3,
        :digest_algorithm => OpenSSL::Digest::SHA256,
        :digest_length    => 32, # 256 / 8
        :logger           => Logger.new($stderr),
        :callback_handler => nil,
      }

      defaults[:error_handler] = lambda do |e|
        message = (["#{e.class}: #{e.message}"] + (e.backtrace || [])).join("\n\tfrom ")

        if self.logger
          self.logger.error(message)
        else
          $stderr.puts(message)
        end
      end

      defaults.each do |k, v|
        self.instance_variable_set("@#{k}", options.fetch(k, v))
      end
    end # initialize

    # 他のクラスのインスタンスを生成して自分自身をセットする
    def create(klass, *args)
      obj = klass.new(*args)
      obj.context = self
      return obj
    end

    # 各種ハンドラプロキシメソッド
    def callback(action, address, timestamp, data)
      if self.callback_handler
        self.callback_handler.call([action, address, timestamp, data])
      end
    end

    def handle_error(e)
      if self.error_handler
        self.error_handler.call(e)
      else
        raise e
      end
    end

    # ノード情報群からハッシュ値とメッセージを生成する
    def digest_and_message(nodes)
      message = nodes.map {|i| i.to_a }.to_msgpack
      hash = OpenSSL::HMAC::digest(self.digest_algorithm.new, self.auth_key, message)
      [hash, message]
    end

    # ロギングプロキシメソッド
    [:fatal, :error, :worn, :info, :debug].each do |name|
      define_method(name) do |message|
        if self.logger
          self.logger.send(name, message)
        else
          $stderr.puts("#{name}: #{message}")
        end
      end
    end

  end # Context

end # RGossip2
