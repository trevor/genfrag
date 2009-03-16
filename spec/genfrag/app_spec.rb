
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. spec_helper]))

#class Runner
#  attr_accessor :name
#  def run(*a, &b) nil; end
#end

describe Genfrag::App do

  before :all do
    @out = StringIO.new
    @err = StringIO.new
  end

  before :each do
#    @runner = ::Runner.new
    @app = Genfrag::App.new(@out, @err)

    Genfrag::App::IndexCommand.stub!(:new)
    Genfrag::App::SearchCommand.stub!(:new)
  end

  after :each do
    @out.clear
    @err.clear
  end

  it 'should provide an index command' do
    @app.cli_run %w[index]
  end

  it 'should provide a search command' do
    @app.cli_run %w[search]
  end

  it 'should provide an info command' do
    pending "feature"
    @app.cli_run %w[info]
  end

  it 'should provide a help command' do
    @app.cli_run %w[--help]
    @out.readline
    @out.readline.should match(%r/GenFrag allows/)
    @out.clear

    @app.cli_run %w[-h]
    @out.readline
    @out.readline.should match(%r/GenFrag allows/)
  end

  it 'should default to the help message if no command is given' do
    @app.cli_run []
    @out.readline
    @out.readline.should match(%r/GenFrag allows/)
  end

  it 'should report an error for unrecognized commands' do
    @app.cli_run %w[bad_func]
    @err.readline.should == 'Unknown command "bad_func"'
  end

  it 'should report a version number' do
    @app.cli_run %w[--version]
    @out.readline.should == "Genfrag #{Genfrag::VERSION}"
    @out.clear

    @app.cli_run %w[-V]
    @out.readline.should == "Genfrag #{Genfrag::VERSION}"
  end

end  # describe Genfrag::App

# EOF
