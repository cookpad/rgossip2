require 'socket'

module RGossip2

  #
  # class Client
  # ゴシッププロトコルのクライアント兼サーバ
  # 
  # +----------+          +--------+
  # |  Client  |<>---+---+|  Node  |
  # +----------+     |    +--------+
  #                  |    +-----------------------+
  #                  +---+|  @node_list:NodeList  |
  #                  |    +-----------------------+
  #                  |    +-----------------------+
  #                  +---+|  @dead_list:NodeList  |
  #                       +-----------------------+
  #
  class Client
    include Enumerable
    include ContextHelper

    attr_reader :node_list
    attr_reader :dead_list
    attr_reader :self_node

    attr_reader :context

    def initialize(context, initial_nodes = [], address = nil, data = nil)
      @context = context

      # データがバッファサイズを超える場合はエラー
      if data and data.length > @context.buffer_size
        raise 'Data is too large'
      end

      # IPアドレスを取得。デフォルトはローカルホストアドレス
      @address = name2addr(address || IPSocket.getaddress(Socket.gethostname))
      info("Client is initialized: initial_nodes=#{initial_nodes.inspect}, address=#{@address}, data=#{data.inspect}")

      # NodeListを生成
      @node_list = create(NodeList)
      @dead_list = create(NodeList)

      # Nodeを生成
      @self_node = create(Node, @node_list, @dead_list, @address, data, nil)
      @self_node.update_timestamp
      @node_list << @self_node

      # 初期ノードを追加
      initial_nodes.uniq.each do |i|
        @node_list << create(Node, @node_list, @dead_list, name2addr(i), nil, nil)
      end

      # Gossiper、Receiverを生成
      @gossiper = create(Gossiper, @self_node, @node_list)
      @receiver = create(Receiver, @self_node, @node_list, @dead_list)
    end

    def start
      # 開始している場合はスキップ
      return if @running

      info("Client is started: address=#{@address}")

      # NodoのTimerをスタート
      @node_list.each do |node|
        if node.address != @self_node.address
          node.start_timer
        end
      end

      @gossiper.start
      @receiver.start
    ensure
      @running = true
    end

    def stop
      # 停止している場合はスキップ
      return unless @running

      info("Client is stopped")

      @gossiper.stop
      @receiver.stop

      @gossiper = nil
      @receiver = nil
    ensure
      @running = true
    end

    def join
      @gossiper.join
      @receiver.join
    end

    def running?
      !!@running
    end

    def address
      @self_node.address
    end

    def data
      @node_list.synchronize {
        @self_node.data
      }
    end

    def data=(v)
      @node_list.synchronize {
        @self_node.data = v
      }
    end

    # ノードの追加
    def add_node(address)
      address = name2addr(address)

      @node_list.synchronize {
        @dead_list.synchronize {
          # すでに存在する場合はエラー
          raise 'The node already exists' if @node_list.any? {|i| i.address == address }

          node = create(Node, @node_list, @dead_list, address, nil, nil)
          @node_list << node

          # デッドリストからは追加したノードを削除
          @dead_list.reject! do |i|
            i.address == address
          end

          node.start_timer if @running

          callback(:add, address, nil, nil)
        }
      }
    end

    # ノードの削除
    def delete_node(address)
      address = name2addr(address)

      # 自分自身は削除できない
      raise 'Own node cannot be deleted' if @self_node.address == address

      @node_list.synchronize {
        @dead_list.synchronize {
          # ノードリストから削除しつつ、Timerを止める
          @node_list.reject! do |i|
            if i.address == address
              i.stop_timer
              true
            end
          end

          # デッドリストからも削除
          @dead_list.reject! do |i|
            i.address == address
          end

          callback(:delete, address, nil, nil)
        }
      }
    end

    # デッドリストのクリーニング
    def clear_dead_list
      @dead_list.synchronize {
        @dead_list.clear
      }
    end

    # ノードを舐める
    def each
      @node_list.each do |node|
        yield([node.address, node.timestamp, node.data])
      end
    end

    private
    def name2addr(name)
      if /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\Z/ =~ name
        name
      else
        IPSocket.getaddress(name)
      end
    end

  end # Client

end # RGossip2
