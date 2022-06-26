require 'rails_helper'

# Several coins inserted into one wallet at the same time, on separate
# connections against committed rows: the buyer row lock must keep every one.
describe Vending::Deposit, :concurrency do
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
  let!(:buyer) { create(:user, :buyer, deposit_amount: 0) }

  let(:results) do
    @results ||= race(connections) do
      described_class.call(buyer: User.find(buyer.id), amount: 10)
    end
  end

  it 'accepts every coin' do
    expect(results).to all(be_success)
  end

  it 'credits every coin' do
    results

    expect(buyer.reload.deposit_amount).to eq(10 * connections)
  end
end
