module RGossip2

  #
  # class Gossiper
  # ゴシッププロトコルの送信クラス
  #
  # +------------+          +--------+
  # |  Gossiper  |<>---+---+|  Node  |
  # +------------+     |    +--------+
  #                    |    +-----------------------+
  #                    +---+|  @node_list:NodeList  |
  #                         +-----------------------+
  #
  class Gossiper

    attr_writer :context

    def initialize(self_node, node_list)
      @self_node = self_node
      @node_list = node_list
    end

    def start
      @context.info("Transmission was started: interval=#{@context.gossip_interval}, port=#{@context.port}")

      @running = true

      # パケット送信スレッドを開始
      @thread = Thread.start {
        begin
          sock = UDPSocket.open

          while @running
            begin
              @node_list.synchronize { gossip(sock) }
            rescue Exception => e
              @context.handle_error(e)
            end

            sleep(@context.gossip_interval)
          end
        ensure
          sock.close
        end
      }
    end # start

    def stop
      @context.info("Transmission was stopped")

      # フラグをfalseにしてスレッドを終了させる
      @running = false
    end

    def join
      @thread.join
    end

    private

    # 送信処理の本体
    def gossip(sock)
      # 送信前にタイムスタンプを更新する
      @self_node.update_timestamp

      # ランダムで送信先を決定
      dest = @node_list.choose_except(@self_node)
      return unless dest # ないとは思うけど…

      @context.debug("Data is transmitted: address=#{dest.address}")

      # チャンクに分けてデータを送信
      @node_list.serialize.each do |chunk|
        sock.send(chunk, 0, dest.address, @context.port)
      end
    end

  end # Gossiper

end # RGossip2
