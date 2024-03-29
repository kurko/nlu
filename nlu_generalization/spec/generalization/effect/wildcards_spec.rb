require "spec_helper"

RSpec.describe NLU::Generalization::Effect, "Wildcards" do
  subject { described_class.new(cause: cause, learned: learned, symbols: symbols) }

  before do
    $nlu_debug = false
  end

  describe "#calculate" do
    context "a sole wildcard" do
      let(:symbols) do
        symbols = NLU::Generalization::Symbols.new
        symbols.add(type: "wildcard", symbol: "[search]")
      end

      let(:learned) do
        generalization = NLU::Generalization.new(symbols: symbols)
        generalization.teach(cause: "i want a [search]", effect: :search_car)
        generalization.learned
      end

      let(:cause) { "i want a ford focus" }

      it "matches anything in that position" do
        expect(subject.calculate).to eq([{
          fn: :search_car,
          attrs: {
            search: "ford focus"
          },
          score: 0.75
        }])
      end
    end

    context "a wildcard and a known symbol" do
      let(:symbols) do
        symbols = NLU::Generalization::Symbols.new
        symbols.add(type: "wildcard", symbol: "[search]")
        symbols.add(type: "wildcard", symbol: "[query]")
        symbols.add(type: 'make',     symbol: 'ford')
        symbols.add(type: 'make',     symbol: 'gm')
      end

      let(:learned) do
        generalization = NLU::Generalization.new(symbols: symbols)
        generalization.teach(cause: 'eu quero um ford', effect: :search_car)
        generalization.teach(cause: "eu quero um [search]",   effect: :search_car)
        generalization.teach(cause: "eu quero um [query]",    effect: :search_car)
        generalization.learned
      end

      let(:cause) { "eu quero um ford" }

      it "matches anything in that position" do
        expect(subject.calculate).to eq([{
          fn: :search_car,
          attrs: {
            make:   "ford",
            search: "ford",
            query:  "ford",
          },
          score: 2.0
        }])
      end
    end

    context "a wildcard and a known symbol with additional words" do
      let(:symbols) do
        symbols = NLU::Generalization::Symbols.new
        symbols.add(type: "wildcard", symbol: "[search]")
        symbols.add(type: "wildcard", symbol: "[query]")
        symbols.add(type: 'make',     symbol: 'ford')
        symbols.add(type: 'make',     symbol: 'gm')
      end

      let(:learned) do
        generalization = NLU::Generalization.new(symbols: symbols)
        generalization.teach(cause: 'eu quero um ford focus', effect: :search_car)
        generalization.teach(cause: "eu quero um [search]",   effect: :search_car)
        generalization.teach(cause: "eu quero um [query]",    effect: :search_car)
        generalization.learned
      end

      let(:cause) { "eu quero um ford focus" }

      it "matches anything in that position" do
        expect(subject.calculate).to eq([{
          fn: :search_car,
          attrs: {
            make:   "ford",
            search: "ford focus",
            query:  "ford focus",
          },
          score: 1
        }])
      end
    end

    context "a wildcard for the entire sentence and a known symbol" do
      let(:symbols) do
        symbols = NLU::Generalization::Symbols.new
        symbols.add(type: "wildcard", symbol: "[query]")
        symbols.add(type: 'make',     symbol: 'ford')
        symbols.add(type: 'make',     symbol: 'gm')
      end

      let(:learned) do
        generalization = NLU::Generalization.new(symbols: symbols)
        generalization.teach(cause: 'eu quero um ford', effect: :search_car)
        generalization.teach(cause: "[query]",          effect: :search_car)
        generalization.learned
      end

      let(:cause) { "eu quero um ford" }

      it "matches anything in that position" do
        expect(subject.calculate).to eq([{
          fn: :search_car,
          attrs: {
            make:   "ford",
            query:  "eu quero um ford",
          },
          score: 2.0
        }])
      end
    end
  end
end
