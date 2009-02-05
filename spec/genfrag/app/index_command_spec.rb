
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. spec_helper]))

# --------------------------------------------------------------------------
describe Genfrag::App::IndexCommand do

  before :all do
    @out = StringIO.new
    @err = StringIO.new
    @input_dir = File.join(GENFRAG_SPEC_DATA_DIR, 'index_command')
    @output_dir = File.join(GENFRAG_SPEC_TMP_DIR, %w[index_command])
    FileUtils.mkdir(@output_dir) unless File.directory? @output_dir
  end
  
  before :each do
    @app = Genfrag::App::IndexCommand.new(@out, @err)
  end
  
  after :each do
    @out.clear
    @err.clear
  end
  
  describe 'when used from the command-line' do
    it 'should provide a help command and exit' do
      lambda {@app.cli_run %w[--help]}.should raise_error(SystemExit)
      @out.readline.should match(%r/Usage: genfrag index \[options\]/)
      @out.clear

      lambda {@app.cli_run %w[--help]}.should raise_error(SystemExit)
      @out.readline.should match(%r/Usage: genfrag index \[options\]/)
    end
    
    it 'should default to the help message and exit if no command is given' do
      lambda {@app.cli_run %w[]}.should raise_error(SystemExit)
      @out.readline.should match(%r/Usage: genfrag index \[options\]/)
    end
    
    it 'should stop on unrecognized options' do
      lambda {@app.cli_run %w[--bad]}.should raise_error(OptionParser::InvalidOption)
    end

    it 'should recognize a fasta file passed as an argument' do
      pending 'feature'
    end
        
    it 'should recognize multiple fasta files passed as arguments' do
      pending 'feature'
    end
    
    it 'should stop on missing --fasta' do
      lambda {@app.cli_run %w[-v --re5 BstYI --re3 BstYI]}.should raise_error(SystemExit)
    end
    
    it 'should stop on missing --re5' do
      lambda {@app.cli_run %w[-v --fasta a --re3 BstYI]}.should raise_error(SystemExit)
    end
    
    it 'should stop on missing --re3' do
      lambda {@app.cli_run %w[-v --fasta a --re5 BstYI]}.should raise_error(SystemExit)
    end
    
    it "should stop when --re3 is passed something it can't recognize" do
      lambda {@app.cli_run %w[-v --fasta a --re5 BstYI --re3 notanenzyme]}.should raise_error
    end
    
    it "should stop when --re5 is passed something it can't recognize" do
      lambda {@app.cli_run %w[-v --fasta a --re3 BstYI --re5 notanenzyme]}.should raise_error
    end
  end
  
  describe 'command-line option parser' do
    it 'should stop on unrecognized options' do
      lambda {@app.parse %w[--bad]}.should raise_error(OptionParser::InvalidOption)
    end
    
    it 'should recognize verbose' do
      @app.parse(%w[--verbose])
      @app.parse(%w[-v])
    end

    it 'should recognize tracktime' do
      @app.parse(%w[--tracktime])
      @app.parse(%w[-m])
    end
    
    it 'should recognize quiet' do
      @app.parse(%w[--quiet])
      @app.parse(%w[-q])
    end
    
    it 'should recognize re5 with string' do
      @app.parse(%w[--re5 a])
      @app.parse(%w[-5 a])
    end
    
    it 'should recognize re3 with string' do
      @app.parse(%w[--re3 a])
      @app.parse(%w[-3 a])
    end
    
    it 'should recognize sqlite' do
      @app.parse(%w[--sqlite])
      @app.parse(%w[-t])
    end
    
    it 'should recognize lookup with string' do
      @app.parse(%w[--lookup a])
      @app.parse(%w[-l a])
    end
    
    it 'should recognize fasta with string' do
      @app.parse(%w[--fasta a])
      @app.parse(%w[-f a])
    end
    
    it 'should recognize a combination of arguments' do
      @app.parse(%w[-v --re5 a --re3 a])
      @app.parse(%w[--verbose -5 a -3 a])
    end
  end

=begin
  after :each do
    FileUtils.rm_rf(@fm.destination) if @fm.destination
    FileUtils.rm_rf(@fm.archive) if @fm.archive
  end

  it "should have a configurable source" do
    @fm.source.should be_nil

    @fm.source = '/home/user/.mrbones/data'
    @fm.source.should == '/home/user/.mrbones/data'
  end

  it "should have a configurable destination" do
    @fm.destination.should be_nil

    @fm.destination = 'my_new_app'
    @fm.destination.should == 'my_new_app'
  end

  it "should set the archive directory when the destination is set" do
    @fm.archive.should be_nil

    @fm.destination = 'my_new_app'
    @fm.archive.should == 'my_new_app.archive'
  end

  it "should return a list of files to copy" do
    @fm.source = Bones.path 'data'

    ary = @fm._files_to_copy
    ary.length.should == 9

    ary.should == %w[
      .bnsignore
      History.txt.bns
      README.txt.bns
      Rakefile.bns
      bin/NAME.bns
      lib/NAME.rb.bns
      spec/NAME_spec.rb.bns
      spec/spec_helper.rb.bns
      test/test_NAME.rb
    ]
  end

  it "should archive the destination directory if it exists" do
    @fm.destination = Bones.path(%w[spec data bar])
    test(?e, @fm.destination).should == false
    test(?e, @fm.archive).should == false

    FileUtils.mkdir @fm.destination
    @fm.archive_destination
    test(?e, @fm.destination).should == false
    test(?e, @fm.archive).should == true
  end

  it "should rename files and folders containing 'NAME'" do
    @fm.source = Bones.path(%w[spec data data])
    @fm.destination = Bones.path(%w[spec data bar])
    @fm.copy

    @fm._rename(File.join(@fm.destination, 'NAME'), 'tirion')

    dir = File.join(@fm.destination, 'tirion')
    test(?d, dir).should == true
    test(?f, File.join(dir, 'tirion.rb.bns')).should == true
  end

  it "should raise an error when renaming an existing file or folder" do
    @fm.source = Bones.path(%w[spec data data])
    @fm.destination = Bones.path(%w[spec data bar])
    @fm.copy

    lambda {@fm._rename(File.join(@fm.destination, 'NAME'), 'lib')}.
      should raise_error(RuntimeError)
  end

  it "should perform ERb templating on '.bns' files" do
    @fm.source = Bones.path(%w[spec data data])
    @fm.destination = Bones.path(%w[spec data bar])
    @fm.copy
    @fm.finalize('foo_bar')

    dir = @fm.destination
    test(?e, File.join(dir, 'Rakefile.bns')).should == false
    test(?e, File.join(dir, 'README.txt.bns')).should == false
    test(?e, File.join(dir, %w[foo_bar foo_bar.rb.bns])).should == false

    test(?e, File.join(dir, 'Rakefile')).should == true
    test(?e, File.join(dir, 'README.txt')).should == true
    test(?e, File.join(dir, %w[foo_bar foo_bar.rb])).should == true

    txt = File.read(File.join(@fm.destination, %w[foo_bar foo_bar.rb]))
    txt.should == <<-TXT
module FooBar
  def self.foo_bar
    p 'just a test'
  end
end
    TXT
  end

  # ------------------------------------------------------------------------
  describe 'when configured with a repository as a source' do

    it "should recognize a git repository" do
      @fm.source = 'git://github.com/TwP/bones.git'
      @fm.repository.should == :git

      @fm.source = 'git://github.com/TwP/bones.git/'
      @fm.repository.should == :git
    end

    it "should recognize an svn repository" do
      @fm.source = 'file:///home/user/svn/ruby/trunk/apc'
      @fm.repository.should == :svn

      @fm.source = 'http://svn.ruby-lang.org/repos/ruby/branches/ruby_1_8'
      @fm.repository.should == :svn

      @fm.source = 'https://svn.ruby-lang.org/repos/ruby/branches/ruby_1_8'
      @fm.repository.should == :svn

      @fm.source = 'svn://10.10.10.10/project/trunk'
      @fm.repository.should == :svn

      @fm.source = 'svn+ssh://10.10.10.10/project/trunk'
      @fm.repository.should == :svn
    end

    it "should return nil if the source is not a repository" do
      @fm.source = '/some/directory/on/your/hard/drive'
      @fm.repository.should == nil
    end
  end
=end

end

# EOF
