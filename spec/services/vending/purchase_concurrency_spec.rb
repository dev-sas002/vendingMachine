require 'rails_helper'

# Proof that the machine cannot oversell.
#
# These examples run against real, committed rows in real concurrent
# connections, so transactional fixtures are switched off and the rows are
# removed by hand afterwards.
describe Vending::Purchase, :concurrency do
  self.use_transactional_tests = false

  # The most the default connection pool (5) can serve while the example thread
  # holds one itself.
  def concurrent_buyers
    4
  end

  after do
    Product.delete_all
    User.delete_all
  end

  # Releases every thread at once so they genuinely race for the same row.
  def race(count)
    gate = Queue.new
    threads = Array.new(count) do |index|
      Thread.new do
        gate.pop
        ActiveRecord::Base.connection_pool.with_connection { yield(index) }
      end
    end
    count.times { gate << :go }
    threads.map(&:value)
  ensure
    ActiveRecord::Base.connection_pool.reap
  end

  context 'when more buyers than there is stock race for the last items' do
    let(:stock) { 2 }
    let!(:product) { create(:product, price: 10, available_count: stock) }
    let!(:buyers) { Array.new(concurrent_buyers) { create(:user, :buyer, deposit_amount: 100) } }

    let(:results) do
      @results ||= race(concurrent_buyers) do |index|
        described_class.call(buyer: User.find(buyers[index].id),
                             product: Product.find(product.id),
                             quantity: 1)
      end
    end

    it 'sells exactly as many units as it had' do
      expect(results.count(&:success?)).to eq(stock)
    end

    it 'refuses the buyers it could not serve' do
      expect(results.count(&:failure?)).to eq(concurrent_buyers - stock)
    end

    it 'tells the losers the product is sold out' do
      expect(results.select(&:failure?).map(&:error).uniq).to eq([described_class::SOLD_OUT])
    end

    it 'never drives the stock negative' do
      results

      expect(product.reload.available_count).to eq(0)
    end

    it 'charges exactly the buyers it served' do
      results

      charged = buyers.count { |buyer| buyer.reload.deposit_amount == 90 }

      expect(charged).to eq(stock)
    end

    it 'leaves the money of refused buyers alone' do
      results

      untouched = buyers.count { |buyer| buyer.reload.deposit_amount == 100 }

      expect(untouched).to eq(concurrent_buyers - stock)
    end
  end

  context 'when one buyer spends the same balance from several connections' do
    # The row lock on the buyer is what stops a wallet being spent twice.
    let!(:buyer) { create(:user, :buyer, deposit_amount: 30) }
    let!(:product) { create(:product, price: 10, available_count: 100) }

    let(:results) do
      @results ||= race(concurrent_buyers) do
        described_class.call(buyer: User.find(buyer.id),
                             product: Product.find(product.id),
                             quantity: 1)
      end
    end

    it 'never lets the balance go below zero' do
      results

      expect(buyer.reload.deposit_amount).to eq(0)
    end

    it 'sells only what the balance covered' do
      expect(results.count(&:success?)).to eq(3)
    end

    it 'removes exactly the stock it sold' do
      results

      expect(product.reload.available_count).to eq(97)
    end

    it 'refuses the purchase that had no money behind it' do
      expect(results.select(&:failure?).map(&:error))
        .to eq([described_class::INSUFFICIENT_FUNDS])
    end
  end
end
