require 'rgossip2/context'
require 'rgossip2/context_helper'
require 'rgossip2/client'
require 'rgossip2/node'
require 'rgossip2/node_list'
require 'rgossip2/gossiper'
require 'rgossip2/receiver'
require 'rgossip2/timer'

module RGossip2

  # Clientの生成
  # 直接、Client#newは実行しない
  def client(options = {})
    initial_nodes = options.delete(:initial_nodes) || []
    address = options.delete(:address)
    data = options.delete(:data)

    context = Context.new(options)
    Client.new(context, initial_nodes, address, data)
  end
  module_function :client

end # RGossip2
