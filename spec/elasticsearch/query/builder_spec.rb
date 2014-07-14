require 'spec_helper'

describe Elasticsearch::Query::Builder do
  def build(&block)
    described_class.build(&block)
  end

  shared_examples "boolean operators" do
    it "implicitly adds a bool field" do
      f = field_name
      j = build do
        send(f) { field(:x).is(:y) }
      end

      expect(j[:query]).to have_key :bool
      expect(j[:query][:bool]).to have_key f
      expect(j[:query][:bool][f]).to be_a Array
      expect(j[:query][:bool][f][0]).to eq :term => {:x => "y"}
    end

    it "collects multiple clauses" do
      f = field_name
      j = build do
        send(f) { field(:x).is(:y) }
        send(f) { field(:m).is(:n) }
      end

      expect(j[:query][:bool][f].length).to eq 2
      expect(j[:query][:bool][f]).to eq [{term: {x: "y"}}, {term: {m: "n"}}]
    end
  end

  context "#field" do
    it "returns a Field object" do
      expect(described_class.new.field(:foo)).to be_a(Elasticsearch::Query::Field)
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
    let(:field_name) { :should }
    it_behaves_like "boolean operators"
  end

  context "#aggregation" do
    subject do
      build do
        aggregate do
          min(:foo)
          max(:foo).as("biggest_foo")
        end
      end
    end

    it "builds the aggregation" do
      expect(subject[:query][:aggs]["foo_min"]).to eq min: {field: :foo}
    end

    it "aliases aggregations" do
      expect(subject[:query][:aggs]["biggest_foo"]).to eq max: {field: :foo}
    end
  end

  context "#filter" do
    context "given a filter and no query" do
      subject do
        build do
          filter do
            must     { field(:foo).is(:bar) }
            must_not { field(:baz).is(:bin) }
          end
        end
      end

      it "should create a filter" do
        expect(subject).to have_key :query

        subject[:query].tap do |query|
          expect(query).to have_key :filtered
          expect(query[:filtered]).to be_an Array
          query[:filtered][0].tap do |filtered|
            expect(filtered).to have_key :filter
            filtered[:filter].tap do |filter|
              expect(filter).to be_a Hash
              expect(filter).to have_key :bool
              filter[:bool].tap do |bool|
                expect(bool).to have_key :must
                expect(bool).to have_key :must_not
                expect(bool).to_not have_key :should
              end
            end
          end
        end
      end
    end

    context "given a filter and a query" do
      subject do
        build do
          filter do
            query do
              must { field(:foo).gt(:bar) }
            end

            must { field(:whizz).is(:bang) }
          end
        end
      end

      it "should construct both a query and subqueries" do
        expect(subject[:query][:filtered][0]).to have_key :query
        expect(subject[:query][:filtered][0]).to have_key :filter
      end
    end

    it "doesn't permit filtering from within a filter" do
      expect {
        build do
          filter do
            filter do
            end
          end
        end
      }.to raise_exception
    end
  end

  context "#query_string" do
    subject do
      build do
        query_string "foo:bar AND baz:bin"
      end
    end

    it "should build a query string" do
      expect(subject[:query][:bool][:must][0][:query_string][:query]).to eq "foo:bar AND baz:bin"
    end

    context "with a complex options set" do
      subject do
        build do
          query_string "bar", default_field: "foo"
        end
      end

      it "should build a complex query_string query" do
        expect(subject[:query][:bool][:must][0][:query_string][:query]).to eq "bar"
        expect(subject[:query][:bool][:must][0][:query_string][:default_field]).to eq "foo"
      end
    end

    it "should raise an exception when invalid keys are passed" do
      expect {
        build do
          query_string "foo", bad_key: "bad_value"
        end
      }.to raise_error(Elasticsearch::Query::Builder::UnknownOptionsKeyException)
    end
  end

  context "#multi_match" do
    subject {
      build {
        multi_match "some search string", ["title", "message"]
      }
    }

    it "should build a multi_match clause" do
      expect(subject[:query][:bool][:must][0][:multi_match]).to eq( {query: "some search string", fields: ["title", "message"]} )
    end
  end

  it "method_missing's to implicit fields" do
    j = build do
      foobar.must.be(100)
    end

    expect(j[:query][:bool][:must][0]).to eq({:term=>{:foobar=>100}})
  end

  it "raises the normal method_missing when args are passed" do
    expect {
      build {
        foo(100)
      }
    }.to raise_error(NoMethodError)
  end

  context "#sort" do
    subject {
      build {
        foo.must.be(10)
        sort :foo, "ASC"
      }
    }

    it "adds sort criteria" do
      expect(subject[:sort][0][:foo][:order]).to eq("asc")
    end

    it "accepts ASC or DESC strings" do
      expect { build { sort :x, "asc" } }.to_not raise_error
      expect { build { sort :x, "desc" } }.to_not raise_error
    end

    it "accepts ASC or DESC symbols" do
      expect { build { sort :x, :asc } }.to_not raise_error
      expect { build { sort :x, :desc } }.to_not raise_error
    end

    it "rejects other strings" do
      expect { build { sort :x, "up" } }.to raise_error
      expect { build { sort :x, "down" } }.to raise_error
    end

    it "accepts 1 and -1 as sort options" do
      expect { build { sort :x, 1 } }.to_not raise_error
      expect { build { sort :x, -1 } }.to_not raise_error
    end

    it "does not accept other sort integers" do
      expect { build { sort :x, 0 } }.to raise_error
    end

    it "accepts a hash of sort options" do
      j = build do
        sort :foo, reverse: true
      end
      expect(j[:sort][0][:foo][:reverse]).to eq true
    end

    it "doesn't accept other options" do
    end
  end

  it "should provide boolean proxies on fields for one-shot conditions" do
    r = build {
      field(:foo).must.be("hello")
      field(:foo).must_not.be("is it me")
      field(:foo).should.be("you're looking for")
    }
    expect(r[:query][:bool][:must]).to be_present
  end
end