require File.join(File.dirname(__FILE__), './spec_helper')

TEST_SERVER_PORT = 4001
@@em = nil

def with_server options={}, &bl
  Thread.abort_on_exception = true
  @@em ||= Thread.fork do
    EM.run do
      EM.start_server('localhost', TEST_SERVER_PORT, TestServer)      
    end
    exit
  end
  if block_given?
    yield
  end
end

describe Vorhees::Client do
  include Vorhees::Matchers
  Client = Vorhees::Client
  
  context 'mocked socket' do
    before :each do
      @socket = MockSocket.new
      TCPSocket.should_receive(:new).and_return(@socket)
      @client = Client.new
    end


    describe '#send_data' do
      it 'should print a string directly to the socket with the EOF' do
        @client.options[:eof].should == "\n"
        str = '{"msg": "HELLO"}'
        @client.send_data str
        @socket.sent.should == [str + "\n"]
      end

      it 'does not append an extra EOF' do
        @client.options[:eof].should == "\n"
        str = '{"msg": "HELLO"}' + "\n"
        @client.send_data str
        @socket.sent.should == [str]
      end
    end

    describe '#sends' do
      context 'given a hash' do
        it 'sends the hash as JSON with the EOF' do
          data = {'command' => 'HELLO', 'payload' => '0xfff'}
          @client.sends data
          @socket.sent.length.should == 1
          JSON.parse(@socket.sent.first).should == data
        end

      end

      context 'given a string' do
        it 'sends a JSON pair of the default key and the string as the value' do
          @client.options[:key].should == 'command'
          @client.sends 'FOO'
          @socket.sent.should == [JSON.unparse('command' => 'FOO') + @client.eof]
        end

        it 'appends any additional values' do
          @client.sends 'ERROR', :message => 'NOT_FOUND'
          @client.options[:key].should == 'command'
          @socket.sent.length.should == 1
          JSON.parse(@socket.sent.first).should == {'command' => 'ERROR', 'message' => 'NOT_FOUND'}
        end
        
        it 'appends an EOF' do
          data = {'command' => 'HELLO', 'payload' => '0xfff'}
          @client.sends data
          @client.sent.first[-1,1].should == @client.eof
        end
      end
    end
  end
  
  context 'should receive matcher (running against an echo server)' do    
    it 'sanity check' do
      with_server do
        @client = Client.new(:host => 'localhost', :port => TEST_SERVER_PORT)
        @client.sends 'HELLO'
        @client.should receive('{"command":"HELLO"}')
      end
    end
    
    it 'waits for the specified duration' do
      with_server do
        @client = Client.new(:host => 'localhost', :port => TEST_SERVER_PORT)
        @client.sends 'HELLO', :delay => 0.1
        @client.should receive(:hello, :timeout => 0.2)
      end
    end

    it 'throws an error if it does not receive a message in the timeout' do
      with_server do
        @client = Client.new(:host => 'localhost', :port => TEST_SERVER_PORT)
        @client.sends 'HELLO', :delay => 0.2
        lambda {
          @client.should receive(:hello, :timeout => 0.1)
        }.should raise_error(RuntimeError)
      end
    end

    it 'raises if the wrong command (or custom :key value) is returned' do
      with_server do
        @client = Client.new(:host => 'localhost', :port => TEST_SERVER_PORT)
        @client.sends 'HELLO', :delay => 0.2
        
        lambda {
          @client.should receive(:goodbye)
        }.should raise_error #(Spec::Expectations::ExpectationNotMetError, RuntimeError)
      end
    end
    
    it 'raises if any expectations in the block fail' do
      with_server do
        @client = Client.new(:host => 'localhost', :port => TEST_SERVER_PORT)
        @client.sends 'HELLO'
        lambda {          
          @client.should receive(:hello) {|msg| msg['missing'].should_not be_nil }
        }.should raise_error(Spec::Expectations::ExpectationNotMetError)
      end
    end

    it 'yields the message to the block' do
      with_server do
        @client = Client.new(:host => 'localhost', :port => TEST_SERVER_PORT)
        @client.sends 'HELLO', :recipient => 'world'
        recipient = nil
        @client.should receive(:hello) {|msg| recipient = msg['recipient'] }
        recipient.should == 'world'
      end
    end

    it 'prints the message given should receive("?")' do
      # ok, this was probably going overboard ...
      require 'stringio'
      with_server do
        @client = Client.new(:host => 'localhost', :port => TEST_SERVER_PORT)
        @client.sends 'HELLO'
        recipient = nil
        stderr, $stderr = $stderr, StringIO.new('','w+')       
        @client.should receive('?')
        stderr, $stderr = $stderr, stderr
        stderr.rewind
        stderr.read.gsub(/^.*\{|\}.*$/, '').should == '"command"=>"HELLO"' + "\n"
      end
    end
  end  
end
