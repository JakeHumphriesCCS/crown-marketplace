require 'rails_helper'

RSpec.describe Supplier, type: :model do
  subject(:supplier) { build(:supplier) }

  it { is_expected.to be_valid }

  it 'is not valid if name is blank' do
    supplier.name = ''
    expect(supplier).not_to be_valid
  end

  context 'when supplier with branches is destroyed' do
    before do
      supplier.save!
    end

    let!(:first_branch) { create(:branch, supplier: supplier) }
    let!(:second_branch) { create(:branch, supplier: supplier) }

    it 'destroys all its branches when it is destroyed' do
      supplier.destroy!

      expect(Branch.find_by(id: first_branch.id)).to be_nil
      expect(Branch.find_by(id: second_branch.id)).to be_nil
    end
  end

  context 'when supplier with rates is destroyed' do
    before do
      supplier.save!
    end

    let!(:rate) { create(:rate, supplier: supplier) }

    it 'destroys all its rates when it is destroyed' do
      supplier.destroy!

      expect(Rate.find_by(id: rate.id)).to be_nil
    end
  end

  describe '#nominated_worker_rate' do
    it 'returns rate if available for direct provision' do
      create(:rate, supplier: supplier, job_type: 'nominated', mark_up: 0.1)
      expect(supplier.nominated_worker_rate).to eq(0.1)
    end

    it 'returns nil if unavailable for direct provision' do
      create(:master_vendor_rate, supplier: supplier, job_type: 'nominated', mark_up: 0.1)
      expect(supplier.nominated_worker_rate).to be_nil
    end

    it 'returns nil if unavailable' do
      expect(supplier.nominated_worker_rate).to be_nil
    end
  end

  describe '#fixed_term_rate' do
    it 'returns rate if available for direct provision' do
      create(:rate, supplier: supplier, job_type: 'fixed_term', mark_up: 0.1)
      expect(supplier.fixed_term_rate).to eq(0.1)
    end

    it 'returns nil if unavailable for direct provision' do
      create(:master_vendor_rate, supplier: supplier, job_type: 'fixed_term', mark_up: 0.1)
      expect(supplier.fixed_term_rate).to be_nil
    end

    it 'returns nil if unavailable' do
      expect(supplier.fixed_term_rate).to be_nil
    end
  end

  describe '.with_master_vendor_rates' do
    let!(:supplier_with_master_vendor_rate) do
      create(:supplier).tap do |supplier|
        create(:master_vendor_rate, supplier: supplier)
      end
    end

    let!(:supplier_with_direct_provision_rate) do
      create(:supplier).tap do |supplier|
        create(:direct_provision_rate, supplier: supplier)
      end
    end

    let(:suppliers) { Supplier.with_master_vendor_rates }

    it 'returns suppliers with master vendor rates' do
      expect(suppliers).to include(supplier_with_master_vendor_rate)
    end

    it 'does not return suppliers with direct provision rates' do
      expect(suppliers).not_to include(supplier_with_direct_provision_rate)
    end
  end
end
