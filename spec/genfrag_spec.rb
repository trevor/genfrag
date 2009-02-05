
require File.join(File.dirname(__FILE__), %w[spec_helper])

describe Genfrag do
  
  before :all do
    @root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  end

  it "finds things releative to 'root'" do
    Genfrag.path(%w[lib genfrag debug]).
        should == File.join(@root_dir, %w[lib genfrag debug])
  end
  
end

# EOF
