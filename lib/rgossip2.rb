require 'rgossip2/context'
require 'rgossip2/client'
require 'rgossip2/node'
require 'rgossip2/node_list'
require 'rgossip2/gossipper'
require 'rgossip2/receiver'
require 'rgossip2/timer'

module RGossip2

  # Clientの生成
  # 直接、Client#newは実行しない
  def client(initial_nodes = [], address = nil, data = nil, options = {})
    context = Context.new(options)
    context.create(Client, initial_nodes, address, data)
  end
  module_function :client

end # RGossip2

