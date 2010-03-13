require 'socket'
require 'json'

unless Object.const_defined?('ActiveSupport')
  class Hash
    # Return a new hash with all keys converted to symbols.
    def symbolize_keys
      inject({}) do |options, (key, value)|
        options[(key.to_sym rescue key) || key] = value
        options
      end
    end

    # Destructively convert all keys to symbols.
    def symbolize_keys!
      self.replace(self.symbolize_keys)
    end
  end
end

module Vorhees
  class Client  
    attr_accessor :socket, :buffer, :sent, :received, :options, :env

    SystemTimer = Timeout if RUBY_VERSION < '1.9'

    GOT_NOTHING  = nil
    GOT_DATA     = 1
    GOT_MESSAGE  = 2

    #cattr_accessor :defaults
    def self.defaults
      @@defaults
    end

    @@defaults = {
      :timeout => 0.06,
      :eof     => "\n",
      :key     => 'command',
      :host    => 'localhost',
      :port    => 80,
      :bufsize => 1024
    }

    def self.const_missing k
      if k =~ /^DEFAULT_(.*)$/
        @@defaults[$1.to_s.downcase.to_sym]
      else super
      end
    end

    def self.set_defaults(options={})    
      defaults.merge! options.symbolize_keys!
    end

    def initialize(options={})    
      @options  = Client.defaults.merge(options.symbolize_keys!)
      @socket   = TCPSocket.new(options[:host], options[:port])
      @env      = {}
      @buffer   = ''
      clear
    end

    def eof
      options[:eof]
    end
    
    alias :messages :received

    # client.sends 'ERROR', :message => 'INVALID_RECORD' 
    # => '{"command":"ERROR", "message":"INVALID_RECORD"}'
    def sends *args
      if args.last.is_a?(Hash)
        send_message(*args)
      else
        begin
          JSON.unparse(args.flatten.first)
          send_data(*args)
        rescue
          send_message(*args)
        end
      end
    end 
  
    def send_message *args
      values = args.last.is_a?(Hash) ? args.pop : {}
      values[options[:key]] = args.shift if args.first.is_a?(String)
      send_json values
    end 
  
    def send_json hash
      send_data hash.to_json # JSON.unparse(hash)
    end 
  
    def send_data(data)
      data = data.chomp(options[:eof]) + eof
      sent << data
      socket.print data
      socket.flush
    end

    def wait_for_responses(opts={})
      wait_for opts do
        if options[:exactly]
          received.length == options[:exactly]
        else
          received.length >=(options[:at_least] || 1)        
        end
      end
      received
    end
  
    def wait_for_response opts={}
      opts = options.merge(opts)
      response = wait_for_responses opts
      yield(response.first && response.first.parse) if block_given?
      response.first
    end
    alias :response :wait_for_response
  
    # FIXME use wait_for, clean this up
    def discard_responses_until(value, opts={})
      opts = options.merge(opts)
      SystemTimer.timeout(opts[:timeout]) do
        loop do
          wait_for_response opts do |msg|
            if msg && msg[Client::DEFAULT_KEY] == value
              return msg
            else
              opts[:debug] ? p(received.shift) : received.shift
            end
          end        
        end
      end
    end
  
    def wait_for opts={}, &block
      opts = options.merge(opts)
      assertion_failed = nil
      test = lambda do
        begin
          yield
        rescue Spec::Expectations::ExpectationNotMetError => e
          assertion_failed = true
          # if there's a background server running, now is a good time
          # to let it do it's thing.        
          Thread.pass
          retry
        end         
      end
      SystemTimer.timeout(opts[:timeout]) do
        until test.call do
          receive_data options
        end
      end    
    rescue Timeout::Error
    ensure 
      yield if assertion_failed
    end
  
    def consume_message
      received.shift.parse rescue nil
    end
  
    def consume
      v = received.parse
      @received = [].extend MessageList
      v
    end
  
    def clear
      @sent     = [].extend MessageList
      @received = [].extend MessageList
      # @buffer   = ""
    end 
  
    def connected?
      !disconnected?
    end
  
    # for flash XMLSocket 
    def request_policy_file
      @socket.print "<policy-file-request/>\0"
      self
    end
  
    def disconnected?
      wait_for :timeout => 0.1 do
        begin
          return socket && socket.eof?
        rescue Errno::ECONNRESET
          return true
        end
      end
      return false
    end
  
    module MessageList
      def parse
        map { |json| JSON.parse json }
      end
    end
  
    module MessageString
      def parse
        JSON.parse self
      end
    end

    private
  
    def receive_data opts={}
      opts = options.merge(opts) # not really necessary here
      start_time = Time.now
      begin
        data = socket.read_nonblock opts[:bufsize]      
        if data.match(opts[:eof] || '')
          data, @buffer = (buffer + data).split(opts[:eof]), ''
          data.each {|str| str.extend MessageString }
          @received += data
          @received.extend MessageList
          GOT_MESSAGE
        else
          @buffer += data
          GOT_DATA
        end
        elapsed = (Time.now.to_f - start_time.to_f)
        elapsed = (elapsed * 10000).round / 10000        
      rescue Errno::EAGAIN, EOFError
        # yield to background thread if there is one
        Thread.pass
        GOT_NOTHING
      end
    end

  end
end
