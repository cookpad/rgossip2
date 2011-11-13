module RGossip2

  #
  # class Timer
  # 一定時間でNodeを削除するためのクラス
  # 唯一、Contextを参照しない
  #
  # +--------+        +---------+
  # |  Node  |<>-----+|  Timer  |
  # +--------+        +---------+
  #
  class Timer

    attr_accessor :timeout

    def initialize(timeout, &block)
      @timeout = timeout
      @block = block
    end

    def start
      # 既存のスレッドは破棄
      @thread.kill if alive?
      @start_time = Time.now

      # スタート時点の「開始時刻」を引数に渡す
      @thread = Thread.start(@start_time) {|start_time|
        loop do
          # タイムアウトするまでスリープ
          sleep @timeout

          if @start_time == start_time
            # 開始時刻が変わっていない＝リセットされない場合
            # 破棄の処理を呼び出してループを抜ける（＝スレッドの終了）
            @block.call
            break
          elsif @start_time.nil?
            # Timerがストップされていた場合
            # 何もしないでループを抜ける（＝スレッドの終了）
            break
          else
            # 開始時刻が更新された場合＝リセットされた場合
            # start_timeを更新してループを継続（＝スレッドの継続）
            start_time = @start_time
          end
        end # loop
      } # Thread.start
    end

    # カウントダウンをリセットする
    def reset
      if alive?
        @start_time = Time.now
        @thread.run # 停止中のスレッドを強制起動してスリープ時間を更新
      end
    rescue ThreadError
      # @thread.runで発生する可能性があるが無視
    end

    # カウントダウンを停止する
    def stop
      if alive?
        @start_time = nil
        @thread.run # 停止中のスレッドを強制起動して終了させる
      end
    rescue ThreadError
      # @thread.runで発生する可能性があるが無視
    end

    private
    # @thread: nil  => Timerが開始されていない
    # @thread: dead => Timerはすでに終了
    def alive?
      @thread and @thread.alive?
    end

  end # Timer

end # RGossip2
