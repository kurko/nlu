require "spec_helper"

RSpec.describe NLU::Generalization::Effect do
  subject { described_class.new(cause: cause, learned: learned, symbols: symbols) }

  before do
    $nlu_debug = false
  end

  describe "#calculate" do
    context 'direct lesson to usage' do
      let(:symbols) do
        symbols = NLU::Generalization::Symbols.new
        symbols.add(type: 'subject', symbol: 'i')
        symbols.add(type: 'make',    symbol: 'ford')
        symbols.add(type: 'make',    parse_rule: /gm/)
      end

      let(:learned) do
        generalization = NLU::Generalization.new(symbols: symbols)
        generalization.teach(cause: 'i want a ford', effect: :search_car)
        generalization.teach(cause: 'i want a gm', effect: :search_car)
      end

      let(:cause) { 'i want a ford' }

      it "finds the cause" do
        expect(subject.calculate).to eq([{
          fn: :search_car,
          attrs: {
            subject: "i",
            make: "ford"
          },
          score: 2.0}]
        )
      end

      context "long no-space tokens" do
        let(:learned) do
          generalization = NLU::Generalization.new(symbols: symbols)
          generalization.teach(cause: 'postback_contact_information', effect: :contact_information)
        end

        let(:cause) { 'postback_contact_information' }

        it 'finds the function' do
          expect(subject.calculate).to eq([{
            fn: :contact_information,
            attrs: { },
            score: 1.0}]
          )
        end
      end
    end

    context 'complex lesson to usage' do
      let(:symbols) do
        symbols = NLU::Generalization::Symbols.new
        symbols.add(type: 'subject', symbol: 'i')
        #symbols.add(type: 'subject_wants', symbol: '[type:subject] want')
        symbols.add(type: 'make',    symbol: 'ford')
        symbols.add(type: 'make',    parse_rule: /gm/)
      end

      let(:learned) do
        generalization = NLU::Generalization.new(symbols: symbols)
        generalization.teach(cause: 'i want a ford', effect: :search_car)
        generalization.teach(cause: 'i want a gm',   effect: :search_car)
        generalization.teach(cause: 'i want a gm',   effect: :search_gm_specifically)
      end

      let(:cause) { 'i want a gm' }

      it "finds the cause" do
        #ap learned
        expect(subject.calculate).to eq([{
          fn: :search_car,
          attrs: {
            subject: "i",
            make: "gm"
          },
          score: 2.0
        }, {
          fn: :search_gm_specifically,
          attrs: {
            subject: "i",
            make: "gm"
          },
          score: 2.0
        }])
      end
    end
  end
end
