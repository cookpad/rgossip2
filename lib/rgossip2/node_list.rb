require 'forwardable'
require 'openssl'
require 'thread'

module RGossip2

  #
  # class NodeList
  # Nodeのコンテナ
  #
  # +------------+           +------------+        +--------+
  # |  Gossiper  |<>---+---+ |  NodeList  |<>-----+|  Node  |
  # +------------+     |     +------------+        +--------+
  # +------------+     |
  # |  Receiver  |<>---+
  # +------------+
  #
  class NodeList
    include ContextHelper
    extend Forwardable

    def initialize(context)
      @context = context
      @nodes = {}
      @mutex = Mutex.new
    end

    # Hashに委譲
    def_delegators :@nodes, :[], :[]=, :delete, :clear

    # Nodeの配列でイテレートする
    def each
      @nodes.values.each do |i|
        yield(i)
      end
    end

    # Mutex_mだとエラーになるので自前で定義
    def synchronize
      @mutex.synchronize do
        yield
      end
    end

    # 指定したNode以外のNodeをリストからランダムに選択する
    def choose_except(node)
      node_list = []

      @nodes.each do |k, v|
        node_list << v if k != node.address
      end

      node_list.empty? ? nil : node_list[rand(node_list.size)]
    end

    # ノード情報をいくつかの塊にごとにシリアライズする
    def serialize
      chunks = []
      nodes = []
      datasum = ''

      # バッファサイズ
      bufsiz = @context.buffer_size - @context.digest_length

      # Nodeはランダムな順序に変換
      @nodes.sort_by { rand }.each do |addr, node|
        # 長さを知るためにシリアライズ
        packed = node.serialize

        # シリアライズしてバッファサイズ以下ならチャンクに追加
        if (datasum + packed).length <= bufsiz
          nodes << node
          datasum << packed
        else
          chunks << digest_and_message(nodes).join
          nodes.clear
          datasum.replace('')

          # バッファサイズを超える場合は次のチャンクに追加
          redo
        end
      end

      # 残りのNodeをチャンクに追加
      unless nodes.empty?
        chunks << digest_and_message(nodes).join
      end

      return chunks
    end # serialize

  end # Nodes

end # RGossip2
