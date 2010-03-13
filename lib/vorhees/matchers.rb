module Vorhees
  module Matchers

    def receive_nothing(options={})
      Spec::Matchers::Matcher.new :receive_nothing do
        match do |client|
          client.clear
          if client.received.empty?
            client.wait_for_responses options
          end
          client.received.empty?         
        end
      
        failure_message_for_should do |client|
          "Expected nothing but received #{client.received}"
        end
      end
    end
  
    def receive(expected=nil, options={})
      Spec::Matchers::Matcher.new :receive, expected do |_expected_|
        raw = nil
        msg = nil
        err = nil
      
        match do |client|
          if client.received.empty?
            client.wait_for_responses options
          end
          if expected == false && !block_given?
            raw = client.received.shift
            msg = raw.parse if raw
            client.received.empty? 
          else
            raw = client.received.shift || raise('No Message Received') 
            msg = raw.parse          
            if block_given?
              begin
                msg['command'].should == expected.to_s.upcase if expected
                yield msg # stick expectations in the block
                true
              rescue Spec::Expectations::ExpectationNotMetError => e
                err = e
                false
              end
            else
              case expected
              when '?'
                $stderr.puts ' ?? -----> ' + msg.inspect
                true
              when String
                msg == JSON.parse(expected)
              when Symbol
                msg['command'] == expected.to_s.upcase
              else
                msg == expected
              end
            end
          
          end
        end # match

        failure_message_for_should do |actual|
          if err
            "#{err.inspect} \n\n-- #{raw}"
          elsif expected == false
            "Expected no message but received #{raw.inspect}"
          elsif msg.nil?
            "Expected a message, but got nothing."
          else
            "Expected #{expected.inspect} but received #{msg.inspect} --> #{raw}"
          end
        end

      end
    end
  end
end
