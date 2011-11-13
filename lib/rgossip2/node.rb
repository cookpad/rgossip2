require 'msgpack'

module RGossip2

  #
  # class Node
  # ノード情報を格納するクラス
  # タイムアウトすると破棄される（＝デッドリストに追加される）
  #
  # +------------+          +--------+          +-----------------------+
  # |  NodeList  |<>---+---+|  Node  |<>---+---+|  @node_list:NodeList  |
  # +------------+     |    +--------+     |    +-----------------------+
  # +------------+     |                   |    +-----------------------+
  # |  Receiver  |<>---+                   +---+|  @dead_list:NodeList  |
  # +------------+     |                   |    +-----------------------+
  # +------------+     |                   |    +---------+
  # |  Gossiper  |<>---+                   +---+|  Timer  |
  # +------------+                              +---------+
  #
  class Node
    include ContextHelper

    attr_reader   :address
    attr_accessor :timestamp
    attr_accessor :data

    # クラスの生成・初期化はContextクラスからのみ行う
    # addressはユニークであること
    def initialize(context, node_list, dead_list, address, data, timestamp)
      @context = context

      @node_list = node_list
      @dead_list = dead_list
      @address = address
      @data = data
      @timestamp = timestamp || ''

      # node_lifetimeの時間内に更新されない場合
      # TimerがNodeを破棄する
      @timer = Timer.new(@context.node_lifetime) do
        debug("Node timed out: address=#{@address}")

        # ノードリストからNodeを削除
        @node_list.synchronize {
          @node_list.delete(@address)
        }

        # デッドリストにNodeを追加
        @dead_list.synchronize {
          @dead_list[@address] = self
        }

        # 破棄時の処理をコールバック
        callback(:delete, @address, @timestamp, @data)
      end
    end

    # Nodeのタイムスタンプを更新
    def update_timestamp
      now = Time.now
      @timestamp = "#{now.tv_sec}#{now.tv_usec}"
    end

    # Arrayへの変換
    def to_a
      [@address, @timestamp, @data]
    end
    alias to_ary to_a

    def start_timer
      debug("Node timer is started: address=#{@address}")
      @timer.start
    end

    def reset_timer
      # 意図的にコメントアウト
      #debug("Node timer is reset: address=#{@address}")
      @timer.timeout = @context.node_lifetime
      @timer.reset
    end

    def stop_timer
      debug("Node timer is suspended: address=#{@address}")
      @timer.stop
    end

    # ノード情報のシリアライズ
    # ただし、シリアライズ後の長さを調べるだけで
    # 実際のデータ送信には使われない
    def serialize
      self.to_a.to_msgpack
    end

  end # Node

end # RGossip2
