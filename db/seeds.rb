# Demo data, so a freshly created database is not an empty machine.
#
# Idempotent: running it twice leaves the same rows. It never runs against a
# production database - demo accounts with a shared password have no business
# being there.
abort('Refusing to seed demo data into production.') if Rails.env.production?

PASSWORD = ENV.fetch('SEED_PASSWORD', 'password123')

def upsert_user!(email:, role:, first_name:, last_name:, deposit_amount: 0)
  User.find_or_initialize_by(email: email).tap do |user|
    user.assign_attributes(
      password: PASSWORD,
      role: role,
      first_name: first_name,
      last_name: last_name,
      deposit_amount: deposit_amount
    )
    user.save!
  end
end

seller = upsert_user!(email: 'seller@example.com', role: :seller,
                      first_name: 'Sam', last_name: 'Seller')
upsert_user!(email: 'buyer@example.com', role: :buyer,
             first_name: 'Bea', last_name: 'Buyer', deposit_amount: 100)

[
  { name: 'Sparkling Water', price: 55, available_count: 12 },
  { name: 'Cola',            price: 70, available_count: 8 },
  { name: 'Salted Crisps',   price: 45, available_count: 6 },
  { name: 'Chocolate Bar',   price: 85, available_count: 4 },
  { name: 'Energy Drink',    price: 120, available_count: 2 },
  { name: 'Chewing Gum',     price: 25, available_count: 0 }
].each do |attributes|
  product = Product.find_or_initialize_by(name: attributes[:name], seller: seller)
  product.update!(attributes.slice(:price, :available_count))
end

Rails.logger.debug do
  "Seeded #{User.count} users and #{Product.count} products. " \
    "Sign in as seller@example.com or buyer@example.com with '#{PASSWORD}'."
end
