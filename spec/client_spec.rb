require File.join(File.dirname(__FILE__), './spec_helper')

describe Vorhees::Client do
  Client = Vorhees::Client
    
  before :each do
    TCPSocket.should_receive(:new).any_number_of_times
  end
  
  describe 'defaults' do
    it 'should be the default options for new instances' do
      c = Vorhees::Client.new
      c.options.should == Vorhees::Client.defaults
    end
    
    it 'should be overridden by any supplied options' do
      c = Vorhees::Client.new 'timeout' => 2, :port => 8080
      c.options[:timeout].should == 2
      c.options[:port].should == 8080
    end
  end
  
  describe 'set_defaults' do
    it 'should change the defaults for new instances' do
      Vorhees::Client.set_defaults 'port' => 8080, :eof => "\000"
      Vorhees::Client.defaults[:port].should == 8080
      Vorhees::Client.defaults[:eof].should == "\000"
      c = Vorhees::Client.new
      c.options[:eof].should == "\000"
      c.options[:port].should == 8080
    end

    it 'should not modify the options of extant instances' do
      c = Vorhees::Client.new
      lambda {
        Vorhees::Client.set_defaults :eof => "\000"
      }.should_not change(c, :options)
    end
  end
  
  describe '#env' do
    it 'should be a user-assignable hash' do
      c = Vorhees::Client.new
      c.env.should == {}
      c.env[:connection_id] = 'foo'
      c.env[:connection_id].should == 'foo'
    end
  end
  
  
  describe 'a new client' do
    describe '#buffer' do
      it 'should be an empty string' do
        Client.new.buffer.should == ''
      end
    end

    describe '#sent' do
      it 'should be empty' do
        Client.new.sent.should == []
      end
    end

    describe '#received' do
      it 'should be empty' do
        Client.new.received.should == []
      end
    end
    
    describe '#socket' do
      it 'should return the raw socket'
    end

    describe '#options' do
      it 'should be the options merged with defaults' do
        o = {:eof => 'XXX'}
        c = Client.new(o)
        c.options[:eof].should == "XXX"
        c.options[:timeout].should == Client.defaults[:timeout]
      end
    end
  end
  
end