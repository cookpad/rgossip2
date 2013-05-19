#require 'msgpack'
# for msgpack 0.5.5
require 'msgpack/version'
require 'msgpack/msgpack'
require 'openssl'

module RGossip2

  #
  # class Receiver
  # ゴシッププロトコルの受信クラス
  #
  # +------------+          +--------+
  # |  Receiver  |<>---+---+|  Node  |
  # +------------+     |    +--------+
  #                    |    +-----------------------+
  #                    +---+|  @node_list:NodeList  |
  #                    |    +-----------------------+
  #                    |    +-----------------------+
  #                    +---+|  @dead_list:NodeList  |
  #                         +-----------------------+
  #
  class Receiver
    include ContextHelper

    def initialize(context, self_node, node_list, dead_list)
      @context = context
      @self_node = self_node
      @node_list = node_list
      @dead_list = dead_list
    end

    def start
      info("Reception is started: port=#{@context.port}")

      @running = true

      # パケット受信スレッドを開始
      @thread = Thread.start {
        begin
          sock = UDPSocket.open
          sock.bind(@self_node.address, @context.port)

          while @running
            receive(sock)
          end
        ensure
          sock.close
        end
      }
    end # start

    def stop
      info("Reception is stopped")

      # フラグをfalseにしてスレッドを終了させる
      @running = false
    end

    def join
      @thread.join
    end

    private

    # 受信処理の本体
    def receive(sock)
      return unless select([sock], [], [], @context.receive_timeout)
      message, (afam, port, host, ip) = sock.recvfrom(@context.buffer_size * @context.allowance)

      # 意図的にコメントアウト
      #debug("Data was received: from=#{ip}")

      recv_nodes = unpack_message(message)

      if recv_nodes
        @node_list.synchronize {
          merge_lists(recv_nodes)
        }
      else
        # データが取得できなかった場合は無効なデータとして処理

        # 意図的にコメントアウト
        #debug("Invalid data was received: from=#{ip}")
      end
    rescue Exception => e
      handle_error(e)
    end

    # ハッシュ値をチェックしてメッセージをデシリアライズ
    def unpack_message(message)
      recv_hash = message.slice!(0, @context.digest_length)
      recv_nodes = MessagePack.unpack(message)
      hash, xxx = digest_and_message(recv_nodes)
      (recv_hash == hash) ? recv_nodes : nil
    rescue MessagePack::UnpackError => e
      return nil
    end

    # ノードのマージ
    def merge_lists(recv_nodes)
      recv_nodes.each do |address, timestamp, data|
        # 自分自身のアドレスならスキップ
        next if address == @self_node.address

        # ノードリストからアドレスの一致するNodeを探す
        if (node = @node_list[address])
          # ノードリストに見つかった場合

          # 受信したNodeのタイムスタンプが新しければ
          # 持っているNodeを更新
          if timestamp > node.timestamp
            # 意図的にコメントアウト
            #debug("The node was updated: address=#{address} timestamp=#{timestamp}")

            node.timestamp = timestamp
            old_data = node.data
            node.data = data
            node.reset_timer

            callback(:update, address, timestamp, data, old_data)
          end
        elsif (node = @dead_list.synchronize { @dead_list[address] })
          # デッドリストに見つかった場合
          @dead_list.synchronize {
            # 受信したNodeのタイムスタンプが新しければ
            # デッドリストのノードを復活させる
            if timestamp > node.timestamp
              # 意図的にコメントアウト
              #debug("Node revived: address=#{address} timestamp=#{timestamp}")

              @dead_list.delete(address)

              # データの更新を忘れずに
              node.timestamp = timestamp
              old_data = node.data
              node.data = data

              @node_list[address] = node
              node.start_timer

              callback(:comeback, address, timestamp, data, old_data)
            end
          }
        else
          # リストにない場合はNodeを追加

          # 意図的にコメントアウト
          #debug("Node was added: address=#{address} timestamp=#{timestamp}")

          node = create(Node, @node_list, @dead_list, address, data, timestamp)
          @node_list[address] = node
          node.start_timer

          callback(:add, address, timestamp, data, data)
        end
      end
    end # merge_lists

  end # Receiver

end # RGossip2
