require File.dirname(__FILE__) + '/spec_helper'

describe Cluster, "with host and port" do
  before do
    @cluster = Cluster.new(:chdir => File.dirname(__FILE__) + '/rails_app',
                           :address => '0.0.0.0',
                           :port => 3000, 
                           :servers => 3,
                           :timeout => 10,
                           :log => 'thin.log',
                           :pid => 'thin.pid'
                          )
    @cluster.script = File.dirname(__FILE__) + '/../bin/thin'
    @cluster.silent = true
  end
    
  it 'should include port number in file names' do
    @cluster.send(:include_server_number, 'thin.log', 3000).should == 'thin.3000.log'
    @cluster.send(:include_server_number, 'thin.pid', 3000).should == 'thin.3000.pid'
  end
    
  it 'should call each server' do
    calls = []
    @cluster.send(:with_each_server) do |port|
      calls << port
    end
    calls.should == [3000, 3001, 3002]
  end
    
  it 'should start on each port' do
    Command.should_receive(:run).with(:start, options_for_port(3000))
    Command.should_receive(:run).with(:start, options_for_port(3001))
    Command.should_receive(:run).with(:start, options_for_port(3002))

    @cluster.start
  end

  it 'should stop on each port' do
    Command.should_receive(:run).with(:stop, options_for_port(3000))
    Command.should_receive(:run).with(:stop, options_for_port(3001))
    Command.should_receive(:run).with(:stop, options_for_port(3002))

    @cluster.stop
  end
  
  private
    def options_for_port(port)
      { :daemonize => true, :log => "thin.#{port}.log", :timeout => 10, :address => "0.0.0.0", :port => port, :pid => "thin.#{port}.pid", :chdir => "./spec/rails_app" }
    end
end

describe Cluster, "with UNIX socket" do
  before do
    @cluster = Cluster.new(:chdir => File.dirname(__FILE__) + '/rails_app',
                           :socket => '/tmp/thin.sock',
                           :address => '0.0.0.0',
                           :port => 3000,
                           :servers => 3,
                           :timeout => 10,
                           :log => 'thin.log',
                           :pid => 'thin.pid'
                          )
    @cluster.script = File.dirname(__FILE__) + '/../bin/thin'
    @cluster.silent = true
  end
  
  it 'should include socket number in file names' do
    @cluster.send(:include_server_number, 'thin.sock', 0).should == 'thin.0.sock'
    @cluster.send(:include_server_number, 'thin', 0).should == 'thin.0'
  end
  
  it 'should call each server' do
    calls = []
    @cluster.send(:with_each_server) do |n|
      calls << n
    end
    calls.should == [0, 1, 2]
  end
  
  it 'should start each server' do
    Command.should_receive(:run).with(:start, options_for_socket(0))
    Command.should_receive(:run).with(:start, options_for_socket(1))
    Command.should_receive(:run).with(:start, options_for_socket(2))

    @cluster.start
  end

  it 'should stop each server' do
    Command.should_receive(:run).with(:stop, options_for_socket(0))
    Command.should_receive(:run).with(:stop, options_for_socket(1))
    Command.should_receive(:run).with(:stop, options_for_socket(2))

    @cluster.stop
  end
  
  
  private
    def options_for_socket(number)
      { :daemonize => true, :log => "thin.#{number}.log", :timeout => 10, :socket => "/tmp/thin.#{number}.sock", :pid => "thin.#{number}.pid", :chdir => "./spec/rails_app" }
    end
end

describe Cluster, "controlling only one server" do
  before do
    @cluster = Cluster.new(:chdir => File.dirname(__FILE__) + '/rails_app',
                           :address => '0.0.0.0',
                           :port => 3000, 
                           :servers => 3,
                           :timeout => 10,
                           :log => 'thin.log',
                           :pid => 'thin.pid',
                           :only => 3001
                          )
    @cluster.script = File.dirname(__FILE__) + '/../bin/thin'
    @cluster.silent = true
  end
  
  it 'should call only specified server' do
    calls = []
    @cluster.send(:with_each_server) do |n|
      calls << n
    end
    calls.should == [3001]
  end
  
  it "should start only specified server" do
    Command.should_receive(:run).with(:start, options_for_port(3001))

    @cluster.start
  end
  
  private
    def options_for_port(port)
      { :daemonize => true, :log => "thin.#{port}.log", :timeout => 10, :address => "0.0.0.0", :port => port, :pid => "thin.#{port}.pid", :chdir => "./spec/rails_app" }
    end
end