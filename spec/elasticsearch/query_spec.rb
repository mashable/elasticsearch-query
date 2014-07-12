require 'spec_helper'

describe Elasticsearch::Query do
  context "#field" do
    it "returns a Field object" do
      expect(Elasticsearch::Query::Builder.new.field(:foo)).to be_a(Elasticsearch::Query::Field)
    end

    it "should provide boolean proxies for one-shot conditions" do
      r = described_class.build do
        field(:foo).must.be("hello")
        field(:foo).must_not.be("is it me")
        field(:foo).should.be("you're looking for")
      end
      p r
      r[:query][:bool][:must].should be_present
    end
  end

  shared_examples "boolean operators" do
    it "implicitly adds a bool field" do
      f = field_name
      j = described_class.build do
        send(f) { field(:x).is(:y) }
      end

      j[:query].should have_key :bool
      j[:query][:bool].should have_key f
      j[:query][:bool][f].should be_a Array
      j[:query][:bool][f][0].should == {:term => {:x => "y"}}
    end

    it "collects multiple clauses" do
      f = field_name
      j = described_class.build do
        send(f) { field(:x).is(:y) }
        send(f) { field(:m).is(:n) }
      end

      j[:query][:bool][f].length.should == 2
      j[:query][:bool][f].should =~ [{term: {x: "y"}}, {term: {m: "n"}}]
    end
  end

  context "#must" do
    let(:field_name) { :must }
    it_behaves_like "boolean operators"
  end

  context "#must_not" do
    let(:field_name) { :must_not }
    it_behaves_like "boolean operators"
  end

  context "#should" do
    let(:field_name) { :must_not }
    it_behaves_like "boolean operators"
  end

  context "#aggregation" do
    subject do
      described_class.build do
        aggregate do
          min(:foo)
        end
      end
    end

    it "builds the aggregation" do
      subject[:query][:aggs]["foo_min"].should == {min: {field: :foo}}
    end
  end

  context "#filter" do
    context "given a filter and no query" do
      subject do
        described_class.build do
          filter do
            must     { field(:foo).is(:bar) }
            must_not { field(:baz).is(:bin) }
          end
        end
      end

      it "should create a filter" do
        subject.should have_key :query

        subject[:query].tap do |query|
          query.should have_key :filtered
          query[:filtered].should be_an Array
          query[:filtered][0].tap do |filtered|
            filtered.should have_key :filter
            filtered[:filter].tap do |filter|
              filter.should be_a Hash
              filter.should have_key :bool
              filter[:bool].tap do |bool|
                bool.should have_key :must
                bool.should have_key :must_not
                bool.should_not have_key :should
              end
            end
          end
        end
      end
    end

    context "given a filter and a query" do
      subject do
        described_class.build do
          filter do
            query do
              must { field(:foo).gt(:bar) }
            end

            must { field(:whizz).is(:bang) }
          end
        end
      end

      it "should construct both a query and subqueries" do
        subject[:query][:filtered][0].should have_key :query
        subject[:query][:filtered][0].should have_key :filter
      end
    end
  end
end