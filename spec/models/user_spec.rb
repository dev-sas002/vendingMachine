# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  confirmation_sent_at   :datetime
#  confirmation_token     :string           indexed
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  deposit_amount         :bigint           default(0)
#  email                  :string           not null, indexed
#  encrypted_password     :string           not null
#  first_name             :string
#  last_name              :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locale                 :string
#  must_change_password   :boolean          default(FALSE)
#  provider               :string           default("email"), not null, indexed => [uid]
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string           indexed
#  role                   :integer
#  sign_in_count          :integer          default(0)
#  tokens                 :json             not null
#  uid                    :string           not null, indexed => [provider]
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_uid_and_provider      (uid,provider) UNIQUE
#

describe User, type: :model do
  subject(:user) { create(:user) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).scoped_to(:provider).case_insensitive }

    specify do
      is_expected.to validate_inclusion_of(:locale).in_array(I18n.available_locales.map(&:to_s))
    end

    it 'rejects a negative deposit balance' do
      user.deposit_amount = -1

      expect(user).not_to be_valid
    end
  end

  describe '#update_deposit_amount' do
    subject(:user) { create(:user, :buyer, deposit_amount: 100) }

    it 'adds to the balance on a deposit' do
      expect(user.update_deposit_amount(50, 'deposit')).to be(true)
      expect(user.deposit_amount).to eq(150)
    end

    it 'subtracts from the balance on a deduction' do
      expect(user.update_deposit_amount(40, 'deduct')).to be(true)
      expect(user.deposit_amount).to eq(60)
    end

    it 'allows spending the balance down to exactly zero' do
      expect(user.update_deposit_amount(100, 'deduct')).to be(true)
      expect(user.deposit_amount).to eq(0)
    end

    it 'refuses a deduction that would overdraw the balance' do
      expect(user.update_deposit_amount(101, 'deduct')).to be(false)
      expect(user.reload.deposit_amount).to eq(100)
    end

    it 'coerces a string amount coming from request params' do
      expect(user.update_deposit_amount('50', 'deposit')).to be(true)
      expect(user.deposit_amount).to eq(150)
    end

    it 'treats a nil amount as zero rather than raising' do
      expect(user.update_deposit_amount(nil, 'deduct')).to be(true)
      expect(user.deposit_amount).to eq(100)
    end

    it 'rejects a negative amount so a deduction cannot top the balance up' do
      expect(user.update_deposit_amount(-50, 'deduct')).to be(false)
      expect(user.reload.deposit_amount).to eq(100)
    end

    it 'rejects an unknown operation' do
      expect(user.update_deposit_amount(50, 'refund')).to be(false)
      expect(user.reload.deposit_amount).to eq(100)
    end

    it 'starts from zero when the balance is nil' do
      user.update_column(:deposit_amount, nil)

      expect(user.update_deposit_amount(25, 'deposit')).to be(true)
      expect(user.deposit_amount).to eq(25)
    end
  end
end
