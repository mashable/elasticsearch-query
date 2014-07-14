require 'spec_helper'

describe Elasticsearch::Query::Field do
  subject { described_class.new("foo") }

  describe "#lt" do
    it "should add an lt range" do
      subject.lt(100)
      expect( subject.ranges["foo"] ).to eq lt: 100
    end
  end

  describe "#lte" do
    it "should add an lte range" do
      subject.lte(100)
      expect( subject.ranges["foo"] ).to eq lte: 100
    end
  end

  describe "#gt" do
    it "should add an gt range" do
      subject.gt(100)
      expect( subject.ranges["foo"] ).to eq gt: 100
    end
  end

  describe "#gte" do
    it "should add an gte range" do
      subject.gte(100)
      expect( subject.ranges["foo"] ).to eq gte: 100
    end
  end

  describe "#match" do
    it "should match simple text" do
      subject.match "bar"
      expect(subject.ops[:match]["foo"]).to eq query: "bar"
    end

    it "should match phrases" do
      subject.phrase "bar"
      expect(subject.ops[:match_phrase]["foo"]).to eq query: "bar"
    end

    it "should match phrase prefixes" do
      subject.phrase_prefix "bar"
      expect(subject.ops[:match_phrase_prefix]["foo"]).to eq query: "bar"
    end
  end

  describe "#match_all" do
    it "should build a terms op" do
      subject.match_all ["foo", "bar"]
      expect(subject.ops[:terms]).to eq [{"foo" => ["foo", "bar"], minimum_should_match: 2}]
    end
  end

  describe "#match_any" do
    it "should build a terms op" do
      subject.match_any ["foo", "bar"]
      expect(subject.ops[:terms]).to eq [{"foo" => ["foo", "bar"], minimum_should_match: 1}]
    end
  end

  describe "#match_at_least" do
    it "should build a terms op" do
      subject.match_at_least ["foo", "bar", "baz"], 2
      expect(subject.ops[:terms]).to eq [{"foo" => ["foo", "bar", "baz"], minimum_should_match: 2}]
    end
  end

  describe "#regex" do
    it "should build a regex op when given a string" do
      subject.regex ".*"
      expect(subject.ops[:regex][0]).to eq "foo" => ".*"
    end

    it "should build a regex op when given a regex" do
      subject.regex /.*/
      expect(subject.ops[:regex][0]).to eq "foo" => ".*"
    end
  end
end