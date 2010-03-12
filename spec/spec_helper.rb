# -*- coding: utf-8 -*-
$:.unshift File.dirname(__FILE__)

require '.bundle/environment'
Bundler.setup()

require 'pp'
# require 'spec'
require 'lib/vorhees/client'
require 'lib/vorhees/matchers'
require 'eventmachine'

class MockSocket
  attr_accessor :received, :sent
  
  def initialize
    @received = []
    @sent     = []
  end
  
  def print data
    sent << data
  end

  
  def flush
    # noop
  end  
end

# simple EM json server
class TestServer < EventMachine::Connection
  EOF= "\n"
  
  def post_init
    @buffer = ''
  end
  
  # ensure a null byte at EOF
  def send_data(data)
    unless data[-1] == 0
      data << EOF
    end
    super data
    Thread.pass
  end
  
  def receive_data(data)
    @buffer << data
    @buffer = process_whole_messages(@buffer)    
  end

  # process any whole messages in the buffer,
  # and return the new contents of the buffer
  def process_whole_messages(data)
    return data if data !~ /#{EOF}/ # only process if data contains a \0 char
    messages = data.split(EOF)
    if data =~ /#{EOF}$/
      data = ''
    else
      # remove the last message from the list (because it is incomplete) before processing
      data = messages.pop
    end
    messages.each {|message| process_message(message.strip)}
    return data
  end

  def process_message(ln)
    request = nil            
    begin
      request = JSON.parse(ln)
    rescue JSON::ParserError => e
      error ["CorruptJSON", ln]
      send_error 'corrupt_JSON'
      raise ['CorruptJSON', ln].inspect
    end
    dispatch request
  end
  
  def dispatch(request)
    # usually this would be a case on request['command']
    # in this case just delay delivery if the request contains
    # 'delay' => sec
    delay = request['delay'].to_f
    if delay > 0
      EM::Timer.new(delay) do
        send_data request.to_json + EOF
      end      
    else
      send_data request.to_json + EOF
    end
  end
end
