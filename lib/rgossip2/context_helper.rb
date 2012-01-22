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
    def callback(action, address, timestamp, data, old_data)
      if @context.callback_handler
        __proc_yield_protect__(@context.callback_handler, action, address, timestamp, data, old_data)
      end
    end

    def handle_error(e)
      if @context.error_handler
        __proc_yield_protect__(@context.error_handler, e)
      else
        raise e
      end
    end

    def __proc_yield_protect__(proc, *args)
      case proc.arity
      when 0
        proc.call
      when 1
        proc.call((args.length < 2) ? args.first : args)
      else
        proc.call(*args)
      end
    rescue Exception => e
      message = (["#{e.class}: #{e.message}"] + (e.backtrace || [])).join("\n\tfrom ")

      if @context.logger
        @context.logger.error(message)
      else
        $stderr.puts(message)
      end
    end

    # ノード情報群からハッシュ値とメッセージを生成する
    def digest_and_message(nodes)
      message = nodes.map {|i| i.to_a }.to_msgpack
      hash = OpenSSL::HMAC::digest(@context.digest_algorithm.new, @context.auth_key, message)
      [hash, message]
    end

    # ロギングプロキシメソッド
    [:fatal, :error, [:warn, :warning], :info, :debug].each do |level, name|
      name = level unless name
      define_method(name) do |message|
        if @context.logger
          @context.logger.send(level, message)
        else
          $stderr.puts("#{level}: #{message}")
        end
      end
    end

  end # ContextHelper

end # RGossip2
