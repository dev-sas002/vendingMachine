# devise_token_auth serializes `tokens` with a coder whose empty value is {}.
# Rails 7.1+ writes a serialized attribute that equals the coder's empty value
# as NULL, so a fresh user could no longer be inserted against the original
# NOT NULL constraint. The gem's own migration template leaves the column
# nullable and reads NULL back as {}; this matches it.
class AllowNullUserTokens < ActiveRecord::Migration[7.2]
  def change
    change_column_null :users, :tokens, true
  end
end
