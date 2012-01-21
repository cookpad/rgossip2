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
    attr_accessor :allowance

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

    # 初期ノードのUDPスキャンのタイムアウト
    attr_accessor :udp_timeout

    # ロガー
    attr_accessor :logger

    # 各種ハンドラ
    attr_accessor :callback_handler
    attr_accessor :error_handler

    def initialize(options = {})
      unless @auth_key = options[:auth_key]
        raise ':auth_key is required'
      end

      default_logger = Logger.new($stderr)
      default_logger.level = Logger::INFO

      defaults = {
        :port             => 10870,
        :buffer_size      => 512,
        :allowance        => 3,
        :node_lifetime    => 10,
        :gossip_interval  => 0.1,
        :receive_timeout  => 3,
        :digest_algorithm => OpenSSL::Digest::SHA256,
        :digest_length    => 32, # 256 / 8
        :logger           => default_logger,
        :udp_timeout      => 0.3,
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

  end # Context

end # RGossip2
