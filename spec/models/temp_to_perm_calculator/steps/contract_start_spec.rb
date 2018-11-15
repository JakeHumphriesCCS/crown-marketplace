require 'rails_helper'

module TempToPermCalculator
  module Steps
    RSpec.describe ContractStart, type: :model do
      subject(:step) do
        described_class.new(
          contract_start_day: day,
          contract_start_month: month,
          contract_start_year: year
        )
      end

      let(:day) { 1 }
      let(:month) { 1 }
      let(:year) { 1970 }

      it { is_expected.to be_valid }

      describe '#next_step_class' do
        it 'is HireDate' do
          expect(step.next_step_class).to eq(HireDate)
        end
      end

      context 'with a missing year' do
        let(:year) { nil }

        it { is_expected.to be_invalid }
      end

      context 'with a missing month' do
        let(:month) { nil }

        it { is_expected.to be_invalid }
      end

      context 'with a missing day' do
        let(:day) { nil }

        it { is_expected.to be_invalid }
      end

      context 'with a non-numeric year' do
        let(:year) { 'abc' }

        it { is_expected.to be_invalid }
      end

      context 'with a non-numeric month' do
        let(:month) { 'abc' }

        it { is_expected.to be_invalid }
      end

      context 'with a non-numeric day' do
        let(:day) { 'abc' }

        it { is_expected.to be_invalid }
      end

      context 'with a nonsense day' do
        let(:day) { 123 }

        it { is_expected.to be_invalid }
      end

      context 'with a nonsense month' do
        let(:month) { 13 }

        it { is_expected.to be_invalid }
      end
    end
  end
end