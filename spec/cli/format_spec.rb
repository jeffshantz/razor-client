# -*- encoding: utf-8 -*-
# Needed to make the client work on Ruby 1.8.7
unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require "rspec/expectations"
require_relative '../spec_helper'

describe Razor::CLI::Format do
  include described_class

  def format(doc, args = {})
    args = {:format => 'short', :args => ['something', 'else'], :query? => true, :show_command_help? => false}.merge(args)
    parse = double(args)
    format_document doc, parse
  end

  context 'additional details' do
    it "tells additional details for a hash" do
      doc = {'abc' => {'def' => 'ghi'}}
      result = format doc
      result.should =~ /Query additional details via: `razor something else \[abc\]`\z/
    end
    it "tells additional details for an array" do
      doc = {'abc' => ['def']}
      result = format doc
      result.should =~ /Query additional details via: `razor something else \[abc\]`\z/
    end
    it "tells multiple additional details" do
      doc = {'abc' => ['def'], 'ghi' => {'jkl' => 'mno'}}
      result = format doc
      result.should =~ /Query additional details via: `razor something else \[abc, ghi\]`\z/
    end
    it "tells no additional details for a string" do
      doc = {'abc' => 'def'}
      result = format doc
      result.should_not =~ /Query additional details/
    end
    it "hides array spec array from additional details" do
      doc = {'abc' => [], 'spec' => ['def', 'jkl']}
      result = format doc
      result.should =~ /Query additional details via: `razor something else \[abc\]`\z/
    end
    it "hides array +spec array from additional details" do
      doc = {'abc' => [], '+spec' => ['def', 'jkl']}
      result = format doc
      result.should =~ /Query additional details via: `razor something else \[abc\]`\z/
    end
    it "only shows additional details for nested objects" do
      doc = {'one-prop' => 'val', 'abc' => [], 'prop' => 'jkl'}
      result = format doc
      result.should =~ /Query additional details via: `razor something else \[abc\]`\z/
    end
    it "tells how to query by name" do
      doc = {'items' => [{'name' => 'entirely'}, {'name' => 'bar'} ]}
      result = format doc
      result.should =~ /Query an entry by including its name, e.g. `razor something else entirely`\z/
    end
    it "hides for commands" do
      doc = {'items' => [{'name' => 'entirely'}, {'name' => 'bar'} ]}
      result = format doc, query?: false
      result.should_not =~ /Query an entry by including its name/
    end
  end

  context 'empty display' do
    it "works right when it has nothing to display as a table" do
      doc = {"spec"=>"http://api.puppetlabs.com/razor/v1/collections/policies", "items"=>[]}
      result = format doc
      result.should == "There are no items for this query."
    end
    it "works right when it has nothing to display as a list" do
      doc = {"spec"=>"http://api.puppetlabs.com/razor/v1/collections/policies/member", "items"=>[]}
      result = format doc
      result.should == "There are no items for this query."
    end
  end

  context 'tabular display' do
    it "works right when columns do not match up" do
      doc = {"spec"=>"http://api.puppetlabs.com/razor/v1/collections/nodes/log",
             "items"=>[{'a' => 'b', 'c' => 'd'},
                       {'b' => 'c', 'e' => 'f'}]}
      result = format doc
      result.should ==
          # The framework seems to be adding unnecessary spaces at the end of each data line;
          # Working around this by adding \s to the expectation.

          # Unicode:
#┏━━━┳━━━┳━━━┳━━━┓
#┃ a ┃ c ┃ b ┃ e ┃\s
#┣━━━╊━━━╊━━━╊━━━┫
#┃ b ┃ d ┃   ┃   ┃\s
#┣━━━╊━━━╊━━━╊━━━┫
#┃   ┃   ┃ c ┃ f ┃\s
#┗━━━┻━━━┻━━━┻━━━┛
          # ASCII:
          <<-OUTPUT.rstrip
+---+---+---+---+
| a | c | b | e |\s
+---+---+---+---+
| b | d |   |   |\s
+---+---+---+---+
|   |   | c | f |\s
+---+---+---+---+
          OUTPUT
    end

    it "works right with unicode" do
      doc = {"spec"=>"http://api.puppetlabs.com/razor/v1/collections/nodes/log",
             "items"=>[{'a' => 'ᓱᓴᓐ ᐊᒡᓗᒃᑲᖅ'}]}
      result = format doc
      result.should ==
          # The framework seems to be adding unnecessary spaces at the end of each data line;
          # Working around this by adding \s to the expectation.

          # Unicode:
#┏━━━━━━━━━━━━┓
#┃ a          ┃\s
#┣━━━━━━━━━━━━┫
#┃ ᓱᓴᓐ ᐊᒡᓗᒃᑲᖅ ┃\s
#┗━━━━━━━━━━━━┛
          # ASCII:
          <<-OUTPUT.rstrip
+------------+
| a          |\s
+------------+
| ᓱᓴᓐ ᐊᒡᓗᒃᑲᖅ |\s
+------------+
OUTPUT
    end
  end
end