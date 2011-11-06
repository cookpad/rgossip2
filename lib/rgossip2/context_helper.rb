module RGossip2

  #
  # module ContextHelper
  # レシーバなしでコンテキストを操作するためのモジュール
  #
  module ContextHelper

    private

    def create(*args)
      @context.create(*args)
    end

    # 他のクラスのインスタンスを生成して自分自身をセットする
    def create(klass, *args)
      klass.new(@context, *args)
    end

    # 各種ハンドラプロキシメソッド
    def callback(action, address, timestamp, data)
      if @context.callback_handler
        @context.callback_handler.yield([action, address, timestamp, data])
      end
    end

    def handle_error(e)
      if @context.error_handler
        @context.error_handler.yield(e)
      else
        raise e
      end
    end

    # ノード情報群からハッシュ値とメッセージを生成する
    def digest_and_message(nodes)
      message = nodes.map {|i| i.to_a }.to_msgpack
      hash = OpenSSL::HMAC::digest(@context.digest_algorithm.new, @context.auth_key, message)
      [hash, message]
    end

    # ロギングプロキシメソッド
    [:fatal, :error, :worn, :info, :debug].each do |name|
      define_method(name) do |message|
        if @context.logger
          @context.logger.send(name, message)
        else
          $stderr.puts("#{name}: #{message}")
        end
      end
    end

  end # ContextHelper

end # RGossip2
