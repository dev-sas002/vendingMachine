require 'rails_helper'

# One balance reset from several connections at once: the buyer row lock must
# make exactly one of them hand the coins back.
describe Vending::Refund, :concurrency do
  self.use_transactional_tests = false

  after do
    User.delete_all
  end

  # Releases every thread at once so they genuinely race for the buyer row.
  def race(count, &operation)
    gate = Queue.new
    threads = Array.new(count) do
      Thread.new do
        gate.pop
        ActiveRecord::Base.connection_pool.with_connection(&operation)
      end
    end
    count.times { gate << :go }
    threads.map(&:value)
  ensure
    ActiveRecord::Base.connection_pool.reap
  end

  let(:connections) { 4 }
  let!(:buyer) { create(:user, :buyer, deposit_amount: 100) }

  let(:results) do
    @results ||= race(connections) do
      described_class.call(buyer: User.find(buyer.id))
    end
  end

  it 'hands the balance back exactly once' do
    expect(results.pluck(:returned_amount).sort)
      .to eq(([0] * (connections - 1)) + [100])
  end

  it 'leaves the wallet empty' do
    results

    expect(buyer.reload.deposit_amount).to eq(0)
  end
end
