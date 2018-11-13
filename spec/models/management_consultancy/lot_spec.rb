require 'rails_helper'

module ManagementConsultancy
  RSpec.describe Lot, type: :model do
    subject(:lots) { described_class.all }

    let(:first_lot) { lots.first }

    it 'loads lots from CSV' do
      expect(lots.count).to eq(4)
    end

    it 'populates attributes of first lot' do
      expect(first_lot.number).to eq('1')
      expect(first_lot.description).to eq('Business Consultancy')
    end
  end
end